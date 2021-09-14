return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "vimtex#complete#omnifunc",
    filetypes = {"tex", "plaintex"}
  }
end
