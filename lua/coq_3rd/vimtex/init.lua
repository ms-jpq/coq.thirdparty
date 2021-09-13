local omnifunc = require("coq_3rd.trans").omnifunc

return function(spec)
  local omni = omnifunc("vimtex#complete#omnifunc")
  return function(args, callback)
    local row, col = unpack(args.pos)
    local items = omni(row, col)
    callback(items)
  end
end
