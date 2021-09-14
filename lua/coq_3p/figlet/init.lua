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
    if #fonts <= 0 then
      callback {isIncomplete = false, items = {}}
    elseif locked then
      callback(nil)
    else
      locked = true
      local font = utils.pick(fonts)

      local chan =
        vim.fn.jobstart(
        {fig_path, "-c", "-f", font},
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
            local big_fig = table.concat(msg, "\n")
            callback {
              isIncomplete = false,
              items = {
                {
                  label = "🀄️",
                  insertText = utils.snippet_escape(big_fig),
                  detail = big_fig,
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
        callback {isIncomplete = false, items = {}}
      else
        vim.fn.chansend(chan, args.line)
        vim.fn.chanclose(chan, "stdin")
      end
    end
  end
end
