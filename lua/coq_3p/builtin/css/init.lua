return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "csscomplete#CompleteCSS",
    filetypes = {"css", "html", "scss"}
  }
end
