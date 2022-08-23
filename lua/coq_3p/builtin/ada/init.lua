return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "adacomplete#Complete",
    filetypes = {"ada"}
  }
end
