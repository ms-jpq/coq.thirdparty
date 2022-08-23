return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "ccomplete#Complete",
    filetypes = {"c"}
  }
end
