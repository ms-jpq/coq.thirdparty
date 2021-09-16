local trigger = " "

return function(spec)
  local utils = require("coq_3p.utils")

  local cow_path = vim.fn.exepath("cowsay")

  local cows =
    (function()
    local acc = {}

    if #cow_path > 0 then
      local stdout = nil

      local fin = function()
        for idx, line in ipairs(stdout) do
          if idx ~= 1 then
            for _, cow in ipairs(vim.split(line, "%s")) do
              if #cow then
                table.insert(acc, cow)
              end
            end
          end
        end
      end

      vim.fn.jobstart(
        {cow_path, "-l"},
        {
          stderr_buffered = true,
          stdout_buffered = true,
          on_exit = function(_, code)
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

      return acc
    end
  end)()

  local styles = {"-b", "-d", "-g", "-p", "-s", "-t", "-w", "-y"}

  local locked = false
  return function(args, callback)
    local _, col = unpack(args.pos)
    local before_cursor = utils.split_line(args.line, col)

    if (#cows <= 0) or locked or not vim.endswith(before_cursor, trigger) then
      callback(nil)
    else
      locked = true

      local cow, style = utils.pick(cows), utils.pick(styles)
      local width = tostring(vim.api.nvim_win_get_width(0))

      local stdout = {}
      local fin = function()
        local big_cow = table.concat(stdout, utils.linesep())
        callback {
          isIncomplete = false,
          items = {
            {
              label = "🐮",
              insertText = utils.snippet_escape(big_cow),
              detail = big_cow,
              kind = vim.lsp.protocol.CompletionItemKind.Unit,
              filterText = trigger,
              insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet
            }
          }
        }
      end

      local chan =
        vim.fn.jobstart(
        {cow_path, "-f", cow, style, "-W", width},
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
          on_stdout = function(_, msg)
            vim.list_extend(stdout, msg)
          end
        }
      )

      if chan <= 0 then
        locked = false
        callback(nil)
      else
        local send = vim.trim(before_cursor)
        vim.fn.chansend(chan, send)
        vim.fn.chanclose(chan, "stdin")
        return function()
          vim.fn.jobstop(chan)
        end
      end
    end
  end
end
