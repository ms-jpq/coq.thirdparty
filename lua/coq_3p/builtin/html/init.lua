return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "htmlcomplete#CompleteTags",
    filetypes = {"html", "xhtml"}
  }
end
