---@class Source
---@field public src string
---@field public short_name string | nil

---@param sources Source[]
return function(sources)
  COQsources = COQsources or {}
  vim.validate {
    COQsources = {COQsources, "table"},
    sources = {sources, "table"}
  }
  local utils = require("coq_3p.utils")

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
        COQsources[utils.new_uid(COQsources)] = {
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
