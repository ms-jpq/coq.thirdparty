local utils = require("coq_3p.utils")

return function(spec)
  vim.g.tabby_trigger_mode = "manual"
  vim.g.tabby_keybinding_accept = "<c-f11>"
  vim.g.tabby_keybinding_trigger_or_dismiss = "<c-f12>"

  local request_id = 0

  local ctx = function(row, col)
    local ls = utils.linesep()
    local buf = vim.api.nvim_get_current_buf()
    local ft = vim.api.nvim_buf_get_option(buf, "filetype")
    local lines = vim.api.nvim_buf_get_text(buf, 0, 0, row, col, {})
    local before = table.concat(lines, ls)
    local pos = vim.fn.strchars(before)
    local around = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text = table.concat(around, ls)
    return {
      filepath = vim.api.nvim_buf_get_name(buf),
      language = ft,
      manually = false,
      position = pos,
      text = text
    }
  end

  local acc = {}

  local resp_cb = function(resp)
    local choices = (function()
      if type(resp) == "table" then
        return resp.choices
      else
        return {}
      end
    end)()
    vim.validate {choices = {choices, "table"}}
    acc = {}
    for _, val in pairs(choices) do
      vim.validate {val = {val, "table"}}
      vim.validate {
        text = {val.text, "string"},
        replaceRange = {val.replaceRange, "table"}
      }
      vim.validate {
        start = {val.replaceRange.start, "number"},
        ["end"] = {val.replaceRange["end"], "number"}
      }
      local v = {
        text = val.text,
        start = val.replaceRange.start,
        fin = val.replaceRange["end"]
      }
      table.insert(acc, v)
    end
  end

  local items = function(row, col, line)
    local items = {}
    for _, val in pairs(acc) do
      vim.validate {val = {val, "table"}}
      vim.validate {
        text = {val.text, "string"},
        start = {val.start, "number"},
        fin = {val.fin, "number"}
      }
      local col_diff = col - val.start
      local almost_same_col = math.abs(col_diff) <= 6
      local fin = (function()
        if val.fin >= col then
          return val.fin
        else
          return val.fin + col_diff
        end
      end)()
      local range = {
        start = {line = row, character = val.start},
        ["end"] = {line = row, character = fin}
      }

      if almost_same_col then
        local item = {
          preselect = true,
          label = val.text,
          documentation = val.text,
          textEdit = {
            newText = val.text,
            range = range
          },
          command = {
            title = "TAB",
            command = "#TAB"
          }
        }
        table.insert(items, item)
      end
    end
    return items
  end

  local fn = function(args, callback)
    if request_id ~= 0 then
      vim.fn["tabby#agent#CancelRequest"](request_id)
    end
    local row, col = unpack(args.pos)

    local request_context = ctx(row, col)
    request_id =
      vim.fn["tabby#agent#ProvideCompletions"](request_context, resp_cb)

    callback(
      {
        isIncomplete = true,
        items = items(row, col, args.line)
      }
    )
  end

  local exec = function()
    if vim.g.coqbug then
      print("#TAB")
    end
  end
  return fn, {exec = exec}
end
