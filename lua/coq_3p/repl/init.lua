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
      return "", "", "", false
    else
      -- parse `-!...`
      local f_match = vim.fn.matchstr(line, [[\v\`\-?\!.+\`\s*$]])
      -- parse out `-! and `
      local match = vim.fn.matchstr(f_match, [[\v(\`\-?\!)@<=.+(\`\s*$)@=]])
      local trim_lines = vim.startswith(f_match, "`-!")

      local exec_path, mapped = (function()
        -- match first word
        local matched = vim.fn.matchstr(match, [[\v^\S+]])
        local maybe_exec = shell[matched]

        if maybe_exec then
          local exec_path = vim.fn.exepath(maybe_exec)
          if #exec_path > 0 then
            return exec_path, true
          end
        end

        return vim.fn.exepath(sh), false
      end)()

      if mapped then
        -- trim first word + spaces
        match = vim.fn.matchstr(match, [[\v(^\S+\s+)@<=.+]])
      end

      return exec_path, f_match, match, trim_lines
    end
  end

  local locked = false
  return function(args, callback)
    local row, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)
    local exec_path, f_match, match, trim_lines = parse(before_cursor)

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

      local stdio = {}
      local fin = function()
        local label = (function()
          for _, line in ipairs(stdio) do
            if #line > 0 then
              return line
            end
          end
          return ""
        end)()

        if #label <= 0 then
          callback(nil)
        else
          local detail = (function()
            for idx = #stdio, 1, -1 do
              if #stdio[idx] > 0 then
                break
              else
                stdio[idx] = nil
              end
            end
            return table.concat(stdio, utils.linesep())
          end)()

          local text_edit =
            (function()
            local before_match =
              string.sub(before_cursor, 1, #before_cursor - #f_match)
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
                label = "🐚 " .. label,
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
          on_exit = function(_, code)
            locked = false
            fin()
          end,
          on_stderr = function(_, msg)
            vim.list_extend(stdio, msg)
          end,
          on_stdout = function(_, msg)
            vim.list_extend(stdio, msg)
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
