return function(source)
  vim.validate {source = {source, "table"}}
  local short_name = source.mark or source.name
  local scope, b_scope = source.scope, source.scope_blacklist or {}

  local comp_fn =
    type(source.on_complete) == "table" and unpack(source.on_complete) or
    source.on_complete
  local resolve_fn = source.on_complete_resolve

  vim.validate {
    name = {source.name, "string"},
    short_name = {short_name, "string"},
    scope = {scope, "table"},
    b_scope = {b_scope, "table"},
    comp_fn = {comp_fn, "string"},
    resolve_fn = {resolve_fn, "string", true}
  }

  -- fn, table of fn name
end
