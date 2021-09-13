local trans = require("coq_3rd.trans").omnifunc

return function(spec)
  local omnifunc =
    trans {
    use_cache = spec.use_cache,
    omnifunc = "vimtex#complete#omnifunc"
  }

  return function(args, callback)
    local row, col = unpack(args.pos)
    local items = omnifunc(row, col)
    callback(items)
  end
end
