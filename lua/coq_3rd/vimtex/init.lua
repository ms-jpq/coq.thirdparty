return function(spec)
  local trans = require("coq_3rd.trans")
  return trans.omni_warp {
    use_cache = true,
    omnifunc = "vimtex#complete#omnifunc",
    filetypes = {"tex", "plaintex"}
  }
end
