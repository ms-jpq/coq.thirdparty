return function(sources)
  COQsources = COQsources or {}

  for _, spec in ipairs(sources) do
    local init = require("coq_3rd." .. spec.src)
    spec.short_name = spec.short_name or string.upper(spec.src)
    init(spec)
  end
end
