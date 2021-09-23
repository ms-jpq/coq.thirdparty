return function(spec)
  local precision = spec.precision or 6
  vim.validate {
    precision = {precision, "number"}
  }

  local utils = require("coq_3p.utils")

  local bc_path = vim.fn.exepath("bc")

  local locked = false
  return function(args, callback)
    local _, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)
    -- match before =
    local match = vim.fn.matchstr(before_cursor, [[\v^.+(\=\s*$)@=]])

    if (#bc_path <= 0) or locked or (#match <= 0) then
      callback(nil)
    else
      locked = true

      local stdout = {}
      local fin = function()
        local ans = table.concat(stdout, "")
        if #ans <= 0 then
          callback(nil)
        else
          local filter_text = (function()
            local spaces = vim.fn.matchstr(before_cursor, [[\v\s+$]])
            if #spaces > 0 then
              return spaces
            else
              return vim.fn.matchstr(before_cursor, [[\v\=\s*$]])
            end
          end)()

          callback {
            isIncomplete = false,
            items = {
              {
                label = "= " .. ans,
                insertText = ans,
                detail = vim.trim(match) .. " = " .. ans,
                filterText = filter_text,
                kind = vim.lsp.protocol.CompletionItemKind.Value
              }
            }
          }
        end
      end

      local chan =
        vim.fn.jobstart(
        {bc_path, "--mathlib"},
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
          on_stderr = function(_, msg)
            utils.debug_err(unpack(msg))
          end,
          on_stdout = function(_, lines)
            vim.list_extend(stdout, lines)
          end
        }
      )

      if chan <= 0 then
        locked = false
        callback(nil)
      else
        local _, c_off = utils.comment()
        local no_comment = c_off(match)
        local scale = "scale=" .. precision .. ";"
        local send = scale .. vim.trim(no_comment) .. "\n"
        vim.fn.chansend(chan, send)
        vim.fn.chanclose(chan, "stdin")
        return function()
          vim.fn.jobstop(chan)
        end
      end
    end
  end
end
