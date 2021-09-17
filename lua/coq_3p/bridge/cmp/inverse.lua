return function()
  COQsources = COQsources or {}
  vim.validate {
    COQsources = {COQsources, "table"}
  }

  local trans = function(key, val)
    local src = {}
    function src:is_available()
      return true
    end
    function src:get_debug_name()
      return "-- BRIDGED coq.nvim --\t" .. tostring(key)
    end
    function src:get_keyword_pattern()
      return ""
    end
    function src:get_trigger_characters()
      return ""
    end
    function src:complete(args, callback)
      val(args, callback)
    end
    function src:resolve(item, callback)
      callback(item)
    end
    function src:execute(item, callback)
      callback(item)
    end
    return src
  end

  local acc = {}

  for key, val in pairs(COQsources) do
    vim.validate {
      val = {val, "function"}
    }
    table.insert(acc, trans(key, val))
  end

  return acc
end
