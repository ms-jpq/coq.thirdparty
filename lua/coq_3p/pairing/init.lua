local utils = require("coq_3p.utils")

return function(spec)
  return function(args, callback)
    local row, col = unpack(args.pos)
    local lhs, _ = utils.split_line(args.line, col)
    local prev = string.sub(lhs, -1)

    local mapping = {
      ["{"] = function()
        local indent = vim.fn.matchstr(lhs, [[\v^\s*]])
        return {
          label = "{}",
          insertText = "{",
          additionalTextEdits = {
            {
              range = {
                start = {line = row + 1, character = 0},
                ["end"] = {line = row + 1, character = 0}
              },
              newText = utils.linesep() .. indent .. "}"
            }
          }
        }
      end
    }


    local items = (function()
      if mapping[prev] then
        local maybe = mapping[prev](lhs)
        if maybe then
          return {maybe}
        end
      end
      return {}
    end)()

    callback {
      isIncomplete = false,
      items = items
    }
  end
end
