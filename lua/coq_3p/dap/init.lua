return function(spec)
  _G.coq_3p_dap_omnifunc = require("dap.repl").omnifunc
  return require("coq_3p.omnifunc") {
    use_cache = true,
    omnifunc = "v:lua.coq_3p_dap_omnifunc",
    filetypes = {"dap-repl"}
  }
end
