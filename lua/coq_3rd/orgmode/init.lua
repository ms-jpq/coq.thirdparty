return function(spec)
  return require("coq_3rd.omnifunc") {
    use_cache = true,
    omnifunc = "OrgmodeOmni",
    filetypes = {"org"}
  }
end
