return function()
  COQsources = COQsources or {}
  vim.validate {
    COQsources = {COQsources, "table"}
  }

  local trans = function(key, val)
    vim.validate {
      val = {val, "function"}
    }

    local src = {}
    function src.is_available()
      return true
    end
    function src.get_debug_name()
      return "-- BRIDGED coq.nvim --\t" .. tostring(key)
    end
    function src.get_keyword_pattern()
      return "\v.$"
    end
    function src.get_trigger_characters()
      return {}
    end
    function src.complete(_, cmp_args, callback)
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
        row = {cmp_args.context.cursor.line, "table"},
        col = {cmp_args.context.cursor.col, "table"}
      }
      local args = {
        uid = cmp_args.time,
        pos = {cmp_args.context.cursor.line, cmp_args.context.cursor.col},
        line = cmp_args.context.cursor_line
      }
      val(args, callback)
    end
    function src.resolve(_, item, callback)
      callback(nil)
    end
    function src.execute(_, item, callback)
      callback(nil)
    end
    return src
  end

  local acc = {}

  for key, val in pairs(COQsources) do
    table.insert(acc, trans(key, val))
  end

  return acc
end
