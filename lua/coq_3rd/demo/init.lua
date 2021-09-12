return function(spec)
  COQsources[vim.fn.tempname()] = {
    fn = function(args, callback)
      callback(nil)
    end
  }
end
