local utils = require("coq_3p.utils")

---@class Source
---@field public src string
---@field public short_name string | nil

---@param sources Source[]
local function setup(sources)
  COQsources = COQsources or {}
  utils.validate {
    COQsources = {COQsources, "table"},
    sources = {sources, "table"}
  }

  for _, spec in ipairs(sources) do
    local cont = function()
      local short_name = spec.short_name or string.upper(spec.src)
      utils.validate {
        src = {spec.src, "string"},
        short_name = {short_name, "string"}
      }
      local mod = "coq_3p." .. spec.src
      local factory = require(mod)
      utils.validate {factory = {factory, "function"}}

      local fn, options = factory(spec)
      local opts = options or {}
      local ln = opts.ln
      local offset_encoding = opts.offset_encoding
      local resolve = opts.resolve
      local exec = opts.exec
      utils.validate {
        fn = {fn, "function", true},
        ln = {ln, "function", true},
        opts = {opts, "table", true},
        offset_encoding = {offset_encoding, "string", true},
        resolve = {resolve, "function", true},
        exec = {exec, "function", true}
      }
      COQsources[utils.new_uid(COQsources)] = {
        name = short_name,
        fn = fn,
        ln = ln,
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

return setmetatable({ setup = setup }, { __call = function(_, ...) setup(...) end })
