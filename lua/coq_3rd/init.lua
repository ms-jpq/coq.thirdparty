return function(sources)
  COQsources = COQsources or {}

  for _, spec in ipairs(sources) do
    if type(spec.src) == "string" then
      local init = require("coq_3rd." .. spec.src)
      spec.short_name = spec.short_name or string.upper(spec.src)
      COQsources[vim.fn.tempname()] = {name = short_name, fn = init(spec)}
    end
  end
end
