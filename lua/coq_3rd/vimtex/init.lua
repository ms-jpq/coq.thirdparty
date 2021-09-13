return function(spec)
  return require("coq_3rd.omnifunc") {
    use_cache = true,
    omnifunc = "vimtex#complete#omnifunc",
    filetypes = {"tex", "plaintex"}
  }
end
