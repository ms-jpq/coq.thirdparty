local utils = require("coq_3p.utils")

return function(spec)
  local trigger = spec.trigger
  local font_spec = spec.font
  vim.validate {trigger = {trigger, "string", true}, font_spec = {font_spec, "string", true}}

  local fig_path = vim.fn.exepath("figlet")

  local fonts = nil
  if font_spec == nil then
    fonts =
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
            on_stderr = function(_, lines)
              utils.debug_err(unpack(lines))
            end,
            on_stdout = function(_, lines)
              stdout = lines
            end
          }
        )

        return acc
      end
    end)()
  else
    fonts = (function() return {font_spec}end)()
  end

  local locked = false
  return function(args, callback)
    local row, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)
    local tail =
      trigger and utils.match_tail(trigger, before_cursor) or
      vim.fn.matchstr(before_cursor, [[\v\S+\s$]])

    if #tail > 0 then
      print(tail)
    end

    if (#fonts <= 0) or locked or (#tail <= 0) then
      callback(nil)
    else
      locked = true

      local font = utils.pick(fonts)
      local width = tostring(vim.api.nvim_win_get_width(0))
      local c_on, c_off = utils.comment()
      local no_comment = c_off(tail)

      local stdio = {}
      local on_io = function(_, lines)
        vim.list_extend(stdio, lines)
      end

      local fin = function()
        local big_fig = (function()
          local acc = vim.tbl_map(c_on, stdio)
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

        local filter_text =
          trigger and trigger or vim.fn.matchstr(no_comment, [[\v\s+$]])

        callback {
          isIncomplete = true,
          items = {
            {
              label = "🏁",
              preselect = trigger and true or vim.NIL,
              textEdit = text_edit,
              detail = big_fig,
              kind = vim.lsp.protocol.CompletionItemKind.Text,
              filterText = filter_text
            }
          }
        }
      end

      local chan =
        vim.fn.jobstart(
        {fig_path, "-f", font, "-w", width},
        {
          stderr_buffered = true,
          on_exit = function(_, code)
            locked = false
            if code == 0 then
              fin()
            else
              callback(nil)
            end
          end,
          on_stderr = on_io,
          on_stdout = on_io
        }
      )

      if chan <= 0 then
        locked = false
        callback(nil)
      else
        local send = vim.trim(no_comment)
        vim.fn.chansend(chan, send)
        vim.fn.chanclose(chan, "stdin")
        return function()
          vim.fn.jobstop(chan)
        end
      end
    end
  end
end
