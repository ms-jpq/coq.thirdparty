return function(cmp_sources)
  COQsources = COQsources or {}
  vim.validate {
    COQsources = {COQsources, "table"},
    cmp_sources = {cmp_sources, "table"}
  }

  for _, cmp_source in pairs(cmp_sources) do
    local 
  end
end
