local uid = function(sources)
  local key = nil
  while true do
    if not key or sources[key] then
      key = math.floor(math.random() * 10000)
    else
      return key
    end
  end
end

return function(sources)
  COQsources = COQsources or {}
  vim.validate {
    COQsources = {COQsources, "table"},
    sources = {sources, "table"}
  }

  for _, spec in ipairs(sources) do
    vim.validate {
      src = {spec.src, "string"},
      short_name = {spec.short_name, "string", true}
    }
    local mod = "coq_3p." .. spec.src
    local go, factory = pcall(require, mod)
    if go then
      local go, fn = pcall(factory, spec)
      if go then
        COQsources[uid(COQsources)] = {
          name = spec.short_name or string.upper(spec.src),
          fn = fn
        }
      else
        vim.api.nvim_err_writeln(fn)
      end
    else
      vim.api.nvim_err_writeln(factory)
    end
  end
end
