return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "phpcomplete#CompletePHP",
    filetypes = {"php"}
  }
end
