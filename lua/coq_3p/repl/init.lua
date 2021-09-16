local trigger = " "

local unsafe_list = {
  "cp",
  "dd",
  "mv",
  "rm",
  "rsync",
  "scp",
  "ssh",
  "su",
  "sudo",
}

return function(spec)
  local shell = spec.shell or {}
  local max_lines = spec.max_lines or 888
  local unsafe = spec.unsafe or unsafe_list

  vim.validate {
    shell = {shell, "table"},
    max_lines = {max_lines, "number"},
    unsafe = {unsafe, "table"}
  }
  for key, val in pairs(shell) do
    vim.validate {
      key = {key, "string"},
      val = {val, "string"}
    }
  end

  local unsafe_set =
    (function()
    local acc = {}
    for key, val in pairs(unsafe) do
      vim.validate {
        key = {key, "number"},
        val = {val, "string"}
      }
      acc[val] = true
    end
    return acc
  end)()

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

      -- parse space + cmd
      local cmd = vim.fn.matchstr(match, [[\v(^\s*)@<=\S+]])
      -- safety check
      if unsafe_set[cmd] then
        utils.debug_err("❌ " .. vim.inspect {cmd, match})
        return "", "", "", false
      else
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

      local chan = -1
      local line_count, stdio = 0, {}
      local kill = function()
        vim.fn.jobstop(chan)
      end
      local on_io = function(_, lines)
        if line_count <= max_lines then
          line_count = line_count + #lines
          vim.list_extend(stdio, lines)
        else
          kill()
        end
      end

      local fin = function()
        local output = vim.list_slice(stdio, 1, max_lines)
        local label = (function()
          for _, line in ipairs(output) do
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
            for idx = #output, 1, -1 do
              if #output[idx] > 0 then
                break
              else
                output[idx] = nil
              end
            end
            return table.concat(output, utils.linesep())
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

      chan =
        vim.fn.jobstart(
        {exec_path},
        {
          on_exit = function(_, code)
            locked = false
            fin()
          end,
          on_stderr = on_io,
          on_stdout = on_io
        }
      )

      if chan <= 0 then
        locked = false
        callback(nil)
      else
        vim.fn.chansend(chan, match)
        vim.fn.chanclose(chan, "stdin")
        return kill
      end
    end
  end
end
