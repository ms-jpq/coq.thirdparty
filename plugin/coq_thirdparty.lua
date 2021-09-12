return function(sources)
  COQsources = COQsources or {}

  for _, source in ipairs(sources) do
    local init = require("coq_3rd" .. source.src)
    init(source.short_name)
  end
end
