local trigger = " "

return function(spec)
  local shell = spec.shell or {}
  vim.validate {
    shell = {shell, "table"}
  }
  for key, val in pairs(shell) do
    vim.validate {
      key = {key, "string"},
      val = {val, "string"}
    }
  end

  local utils = require("coq_3p.utils")
  local sh = vim.env.SHELL or (utils.is_win and "cmd" or "sh")

  local parse = function(line)
    if not vim.endswith(line, trigger) then
      return "", "", false
    else
      local match = vim.fn.matchstr(line, [[\v(\`\!)@<=.+(\`\-?\s*$)@=]])
      local exec = shell[vim.fn.matchstr(match, [[\v^[^\s]+]])] or sh
      local exec_path = vim.fn.exepath(exec)
      local trim_lines = #(vim.fn.matchstr(line, [[\v\-\s*$]])) > 0
      return exec_path, match, trim_lines
    end
  end

  local locked = false
  return function(args, callback)
    local row, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)
    local exec_path, match, trim_lines = parse(before_cursor)

    local text_esc, ins_fmt = (function()
      local fmts = vim.lsp.protocol.InsertTextFormat
      if trim_lines then
        return utils.noop, fmts.PlainText
      else
        return utils.snippet_escape, fmts.Snippet
      end
    end)()

    if (#exec_path <= 0) or locked or (#match <= 0) then
      callback(nil)
    else
      locked = true

      local stdout = nil

      local fin = function()
        local label, detail = (function()
          local fline, lines = "", {}
          local len = #stdout
          for idx, line in ipairs(stdout) do
            if idx == 1 then
              fline = line
            end
            if idx ~= len or #line > 0 then
              table.insert(lines, line)
            end
          end
          return fline, table.concat(lines, utils.linesep())
        end)()

        if #label <= 0 then
          callback(nil)
        else
          local text_edit =
            (function()
            local t_match =
              vim.fn.matchstr(before_cursor, [[\v\`\!.+\`\-?\s*$]])
            local before_match =
              string.sub(before_cursor, 1, #before_cursor - #t_match)
            local _, lo = vim.str_utfindex(before_match)
            local _, hi = vim.str_utfindex(before_cursor)

            local edit = {
              newText = text_esc(detail),
              range = {
                start = {line = row, character = lo},
                ["end"] = {line = row, character = hi}
              }
            }
            return edit
          end)()

          callback {
            isIncomplete = false,
            items = {
              {
                label = label,
                textEdit = text_edit,
                detail = detail,
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                filterText = trigger,
                insertTextFormat = ins_fmt
              }
            }
          }
        end
      end

      local chan =
        vim.fn.jobstart(
        {exec_path},
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
        vim.fn.chansend(chan, match)
        vim.fn.chanclose(chan, "stdin")
        return function()
          vim.fn.jobstop(chan)
        end
      end
    end
  end
end
