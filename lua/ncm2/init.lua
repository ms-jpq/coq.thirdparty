return function(source)
  vim.validate {source = {source, "table"}}
  local short_name = source.mark or source.name
  local scope, b_scope = source.scope, source.scope_blacklist or {}

  vim.validate {
    name = {source.name, "string"},
    short_name = {short_name, "string"},
    scope = {scope, "table"},
    b_scope = {b_scope, "table"}
  }

  -- fn, table of fn name
  local on_complete = source.on_complete
end
