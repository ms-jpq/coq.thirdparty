local utils = require("coq_3p.utils")

return function(spec)
  local sh = spec.sh or vim.env.SHELL or (utils.is_win and "cmd" or "sh")
  local shell = spec.shell or {}
  local max_lines = spec.max_lines or 888
  local deadline = spec.deadline or 888
  local unsafe = spec.unsafe or require("coq_3p.repl.unsafe")

  vim.validate {
    sh = {sh, "string"},
    shell = {shell, "table"},
    max_lines = {max_lines, "number"},
    deadline = {deadline, "number"},
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

  local parse = function(line)
    local bottom = {
      exec_path = "",
      f_match = "",
      match = "",
      control_chars = {}
    }

    local parsed =
      (function()
      -- parse `*!...`
      local f_match = vim.fn.matchstr(line, [[\v\`[\-\#]*\!.*\`.*$]])
      if #f_match <= 0 then
        return bottom
      else
        -- parse out `*! and `
        local match = vim.fn.matchstr(f_match, [[\v%(^\`[^\!]*\!)@<=.*%(\`)@=]])

        local control_chars = (function()
          local chars = vim.fn.matchstr(f_match, [[\v%(^\`)@<=[^\!]*]])
          local acc = {}
          for _, char in ipairs(vim.split(chars, "", true)) do
            acc[char] = true
          end
          return acc
        end)()

        -- parse space + cmd
        local cmd = vim.fn.matchstr(match, [[\v%(^\s*)@<=\S+]])
        -- safety check
        if unsafe_set[cmd] then
          utils.debug_err("❌ " .. vim.inspect {cmd, match})
          return bottom
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
            match = vim.fn.matchstr(match, [[\v%(^\S+\s+)@<=.+]])
          end

          local parsed = {
            exec_path = exec_path,
            f_match = f_match,
            match = match,
            control_chars = control_chars
          }
          return parsed
        end
      end
    end)()

    vim.validate {
      exec_path = {parsed.exec_path, "string"},
      f_match = {parsed.f_match, "string"},
      match = {parsed.match, "string"},
      control_chars = {parsed.control_chars, "table"}
    }
    return parsed
  end

  local locked = false
  return function(args, callback)
    local row, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)
    local parsed = parse(before_cursor)
    local c_on, _ = utils.comment()

    local comment = parsed.control_chars["#"] and c_on or utils.noop
    local ins_mode = parsed.control_chars["-"] and 1 or 2

    if (#parsed.exec_path <= 0) or locked or (#parsed.match <= 0) then
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
            return table.concat(vim.tbl_map(comment, output), utils.linesep())
          end)()

          local text_edit =
            (function()
            local before_match =
              string.sub(before_cursor, 1, #before_cursor - #parsed.f_match)
            local _, lo = vim.str_utfindex(before_match)
            local _, hi = vim.str_utfindex(before_cursor)

            local edit = {
              newText = detail,
              range = {
                start = {line = row, character = lo},
                ["end"] = {line = row, character = hi}
              }
            }
            return edit
          end)()

          local filter_text = (function()
            local spaces = vim.fn.matchstr(parsed.f_match, [[\v\s+$]])
            if #spaces > 0 then
              return spaces
            else
              return vim.fn.matchstr(parsed.f_match, [[\v\W+$]])
            end
          end)()

          local item = {
            label = "🐚 " .. label,
            textEdit = text_edit,
            detail = detail,
            kind = vim.lsp.protocol.CompletionItemKind.Text,
            filterText = filter_text,
            insertTextMode = ins_mode
          }

          callback {
            isIncomplete = true,
            items = {item}
          }
        end
      end

      chan =
        vim.fn.jobstart(
        {parsed.exec_path},
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
        vim.fn.chansend(chan, parsed.match)
        vim.fn.chanclose(chan, "stdin")
        vim.defer_fn(kill, deadline)
        return kill
      end
    end
  end
end
