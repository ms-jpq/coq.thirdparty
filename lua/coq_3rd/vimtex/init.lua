local trans = require("coq_3rd.trans")

return function(spec)
  local omni =
    trans.limit_filetypes(
    spec.filetypes,
    trans.omnifunc(spec.use_cache, "vimtex#complete#omnifunc")
  )

  return function(args, callback)
    local row, col = unpack(args.pos)
    local items = omni(row, col)
    callback(items)
  end
end
