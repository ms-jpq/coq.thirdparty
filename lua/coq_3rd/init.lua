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

  for _, spec in ipairs(sources) do
    if type(spec.src) == "string" then
      local init = require("coq_3rd." .. spec.src)
      spec.short_name = spec.short_name or string.upper(spec.src)
      COQsources[uid(COQsources)] = {name = spec.short_name, fn = init(spec)}
    end
  end
end
