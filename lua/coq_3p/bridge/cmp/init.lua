return function(cmp_sources)
  COQsources = COQsources or {}
  vim.validate {
    COQsources = {COQsources, "table"},
    cmp_sources = {cmp_sources, "table"}
  }

  for _, cmp_source in pairs(cmp_sources) do
    vim.validate {
      cmp_source = {cmp_source, "table"}
    }
    local coq_source = function(args, callback)
      local cmp_args = {}
      cmp_source:complete(cmp_args, callback)
    end
  end
end
