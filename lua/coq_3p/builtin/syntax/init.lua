return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "syntaxcomplete#Complete",
    filetypes = nil
  }
end
