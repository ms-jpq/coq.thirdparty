return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "OrgmodeOmni",
    filetypes = {"org"}
  }
end
