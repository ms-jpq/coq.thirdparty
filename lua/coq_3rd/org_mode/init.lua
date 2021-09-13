return function(spec)
  local trans = require("coq_3rd.trans")
  return trans.omni_warp {
    use_cache = true,
    omnifunc = "OrgmodeOmni",
    filetypes = {"org"}
  }
end
