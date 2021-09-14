return function(spec)
  vim.validate {
    precision = {spec.precision, "number"}
  }

  local utils = require("coq_3p.utils")

  local bc_path = vim.fn.exepath("bc")

  local locked = false
  return function(args, callback)
    local _, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)
    local match = vim.trim(vim.fn.matchstr(before_cursor, [[\v^.+(\=\s*$)@=]]))

    if (#bc_path <= 0) or locked or (#match <= 0) then
      callback(nil)
    else
      locked = true

      local stdout = nil

      local fin = function()
        local ans = table.concat(stdout, "")
        if #ans <= 0 then
          callback(nil)
        else
          callback {
            isIncomplete = false,
            items = {
              {
                label = "= " .. ans,
                insertText = ans,
                detail = match .. " = " .. ans,
                kind = vim.lsp.protocol.CompletionItemKind.Unit
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
          stdout_buffered = true,
          on_exit = function(_, code)
            locked = false
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

      if chan <= 0 then
        locked = false
        callback(nil)
      else
        local scale = "scale=" .. spec.precision .. ";"
        local feed = scale .. match .. "\n"
        vim.fn.chansend(chan, feed)
        vim.fn.chanclose(chan, "stdin")
      end
    end
  end
end
