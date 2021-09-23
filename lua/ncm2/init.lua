return function(source)
  vim.validate {source = {source, "table"}}
  local short_name = source.mark or source.name
  vim.validate {
    name = {source.name, "string"},
    short_name = {short_name, "string"}
  }
  print(vim.inspect {...})
end
