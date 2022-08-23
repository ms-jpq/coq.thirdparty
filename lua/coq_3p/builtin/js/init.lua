return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "javascriptcomplete#CompleteJS",
    filetypes = {"javascript"}
  }
end
