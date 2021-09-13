local trans = require("coq_3rd.trans").omnifunc

return function(spec)
  local omnifunc =
    trans {
    use_cache = true,
    omnifunc = "vimtex#complete#omnifunc",
    filetypes = {"tex", "plaintex"}
  }

  return function(args, callback)
    local row, col = unpack(args.pos)
    local items = omnifunc(row, col)
    callback(items)
  end
end
