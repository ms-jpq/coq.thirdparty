return function(spec)
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "vim_dadbod_completion#omni",
    filetypes = {"sql", "psql"}
  }
end
