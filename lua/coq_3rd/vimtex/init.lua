return function(name)
  COQsources[vim.fn.tempname()] = {
    name = name or "vTEX",
    fn = function(pos, callback)
      callback(nil)
    end
  }
end
