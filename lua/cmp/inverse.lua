return function()
  COQsources = COQsources or {}
  vim.validate {
    COQsources = {COQsources, "table"}
  }

  local utils = require("coq_3p.utils")

  local trans = function(key, val)
    vim.validate {
      val = {val, "function"}
    }

    return utils.freeze(
      "coq_3p.inverse_src",
      {
        is_available = function()
          return true
        end,
        get_debug_name = function()
          return "-- BRIDGED coq.nvim --\t" .. tostring(key)
        end,
        get_keyword_pattern = function()
          return "\v.$"
        end,
        get_trigger_characters = function()
          return {}
        end,
        complete = function(_, cmp_args, callback)
          vim.validate {
            args = {cmp_args, "table"}
          }
          vim.validate {
            time = {cmp_args.time, "number"},
            context = {cmp_args.context, "table"}
          }
          vim.validate {
            cursor = {cmp_args.context.cursor, "table"},
            line = {cmp_args.context.cursor_line, "string"}
          }
          vim.validate {
            row = {cmp_args.context.cursor.line, "number"},
            col = {cmp_args.context.cursor.col, "number"}
          }
          local args = {
            uid = cmp_args.time,
            pos = {cmp_args.context.cursor.line, cmp_args.context.cursor.col},
            line = cmp_args.context.cursor_line
          }
          val(args, callback)
        end,
        resolve = function(_, _, callback)
          callback(nil)
        end,
        execute = function(_, _, callback)
          callback(nil)
        end
      }
    )
  end

  local acc = {}
  for key, val in pairs(COQsources) do
    local src = trans(key, val)
    table.insert(acc, src)
  end
  return acc
end
