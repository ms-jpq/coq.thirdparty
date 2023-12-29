local utils = require("coq_3p.utils")

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

  for _, spec in ipairs(sources) do
    local cont = function()
      local short_name = spec.short_name or string.upper(spec.src)
      vim.validate {
        src = {spec.src, "string"},
        short_name = {short_name, "string"}
      }
      local mod = "coq_3p." .. spec.src
      local factory = require(mod)
      vim.validate {factory = {factory, "function"}}

      local fn, options = factory(spec)
      local opts = options or {}
      local offset_encoding = opts.offset_encoding
      local resolve = opts.resolve
      local exec = opts.exec
      vim.validate {
        fn = {fn, "function"},
        opts = {opts, "table", true},
        offset_encoding = {offset_encoding, "string", true},
        resolve = {resolve, "function", true},
        exec = {exec, "function", true}
      }
      COQsources[utils.new_uid(COQsources)] = {
        name = short_name,
        fn = factory(spec),
        offset_encoding = offset_encoding,
        resolve = resolve,
        exec = exec
      }
    end

    local go, err = pcall(cont)
    if not go then
      vim.api.nvim_err_writeln(err)
    end
  end
end
