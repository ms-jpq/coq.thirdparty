return function(spec)
  local utils = require("coq_3p.utils")

  local cow_path = vim.fn.exepath("cowsay")

  local cows =
    (function()
    local acc = {}
    if #cow_path > 0 then
      vim.fn.jobstart(
        {cow_path, "-l"},
        {
          stderr_buffered = true,
          stdout_buffered = true,
          on_stderr = function(_, msg)
            utils.debug_err(unpack(msg))
          end,
          on_stdout = function(_, msg)
            for idx, line in ipairs(msg) do
              if idx ~= 1 then
                for _, cow in ipairs(vim.split(line, "%s")) do
                  if #cow then
                    table.insert(acc, cow)
                  end
                end
              end
            end
          end
        }
      )
      return acc
    end
  end)()

  local styles = {"-b", "-d", "-g", "-p", "-s", "-t", "-w", "-y"}

  local locked = false
  return function(args, callback)
    if #cows <= 0 or locked then
      callback(nil)
    else
      locked = true
      local cow, style = utils.pick(cows), utils.pick(styles)

      local chan =
        vim.fn.jobstart(
        {cow_path, "-f", cow, style},
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
            local big_cow = table.concat(msg, "\n")
            callback {
              isIncomplete = false,
              items = {
                {
                  label = "🐮",
                  insertText = utils.snippet_escape(big_cow),
                  detail = big_cow,
                  kind = vim.lsp.protocol.CompletionItemKind.Unit,
                  filterText = " ",
                  insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet
                }
              }
            }
          end
        }
      )

      if chan <= 0 then
        locked = false
        callback(nil)
      else
        vim.fn.chansend(chan, args.line)
        vim.fn.chanclose(chan, "stdin")
      end
    end
  end
end
