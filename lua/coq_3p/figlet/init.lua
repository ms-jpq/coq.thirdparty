local trigger = " "

return function(spec)
  local utils = require("coq_3p.utils")

  local fig_path = vim.fn.exepath("figlet")

  local fonts =
    (function()
    local acc = {}
    if #fig_path > 0 then
      vim.fn.jobstart(
        {fig_path, "-I", "2"},
        {
          stderr_buffered = true,
          stdout_buffered = true,
          on_stderr = function(_, msg)
            utils.debug_err(unpack(msg))
          end,
          on_stdout = function(_, msg)
            local fonts_dir = table.concat(msg, "")
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
        }
      )
      return acc
    end
  end)()

  local locked = false
  return function(args, callback)
    local _, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)

    if #fonts <= 0 then
      callback {isIncomplete = false, items = {}}
    elseif locked or not vim.endswith(before_cursor, trigger) then
      callback(nil)
    else
      locked = true
      local font = utils.pick(fonts)

      local chan =
        vim.fn.jobstart(
        {fig_path, "-f", font},
        {
          stderr_buffered = true,
          stdout_buffered = true,
          on_exit = function()
            locked = false
          end,
          on_stderr = function(_, msg)
            utils.debug_err(unpack(msg))
          end,
          on_stdout = function(_, msg)
            local big_fig = (function()
              local lhs, rhs = utils.comment_pairs()
              local acc = {}
              for _, line in ipairs(msg) do
                local commented = lhs .. line .. rhs
                table.insert(acc, commented)
              end
              return table.concat(acc, "\n")
            end)()

            callback {
              isIncomplete = false,
              items = {
                {
                  label = "💭",
                  insertText = "\n" .. big_fig,
                  detail = big_fig,
                  kind = vim.lsp.protocol.CompletionItemKind.Unit,
                  filterText = trigger
                }
              }
            }
          end
        }
      )

      if chan <= 0 then
        locked = false
        callback {isIncomplete = false, items = {}}
      else
        vim.fn.chansend(chan, args.line)
        vim.fn.chanclose(chan, "stdin")
      end
    end
  end
end
