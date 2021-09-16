local trigger = " "

return function(spec)
  local utils = require("coq_3p.utils")

  local fig_path = vim.fn.exepath("figlet")

  local fonts =
    (function()
    local acc = {}

    if #fig_path > 0 then
      local stdout = nil

      local fin = function()
        local fonts_dir = table.concat(stdout, "")
        vim.fn.readdir(
          fonts_dir,
          function(name)
            if vim.endswith(name, ".flf") then
              local font = fonts_dir .. "/" .. name
              table.insert(acc, font)
            end
          end
        )
      end

      vim.fn.jobstart(
        {fig_path, "-I", "2"},
        {
          stderr_buffered = true,
          stdout_buffered = true,
          on_exit = function(_, code)
            if code == 0 and stdout then
              fin()
            end
          end,
          on_stderr = function(_, msg)
            utils.debug_err(unpack(msg))
          end,
          on_stdout = function(_, msg)
            stdout = msg
          end
        }
      )

      return acc
    end
  end)()

  local locked = false
  return function(args, callback)
    local row, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)

    if (#fonts <= 0) or locked or not vim.endswith(before_cursor, trigger) then
      callback(nil)
    else
      locked = true

      local font = utils.pick(fonts)
      local width = tostring(vim.api.nvim_win_get_width(0))
      local c_on, c_off = utils.comment()

      local send = vim.trim(c_off(before_cursor))
      local stdout = nil

      local fin = function()
        local big_fig = (function()
          local acc = {}
          for _, line in ipairs(stdout) do
            table.insert(acc, c_on(line))
          end
          return table.concat(acc, utils.linesep())
        end)()

        local text_edit =
          (function()
          local _, u16 = vim.str_utfindex(args.line)
          local edit = {
            newText = big_fig,
            range = {
              start = {line = row, character = 0},
              ["end"] = {line = row, character = u16}
            }
          }
          return edit
        end)()

        callback {
          isIncomplete = false,
          items = {
            {
              label = "🏁",
              textEdit = text_edit,
              detail = big_fig,
              kind = vim.lsp.protocol.CompletionItemKind.Text,
              filterText = trigger
            }
          }
        }
      end

      local chan =
        vim.fn.jobstart(
        {fig_path, "-f", font, "-w", width},
        {
          stderr_buffered = true,
          stdout_buffered = true,
          on_exit = function(_, code)
            locked = false
            if code == 0 and stdout then
              fin()
            else
              callback(nil)
            end
          end,
          on_stderr = function(_, msg)
            utils.debug_err(unpack(msg))
          end,
          on_stdout = function(_, msg)
            stdout = msg
          end
        }
      )

      if chan <= 0 then
        locked = false
        callback(nil)
      else
        vim.fn.chansend(chan, send)
        vim.fn.chanclose(chan, "stdin")
        return function()
          vim.fn.jobstop(chan)
        end
      end
    end
  end
end
