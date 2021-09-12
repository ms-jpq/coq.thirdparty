return function(spec)
  return function(args, callback)
    local items = {}

    for key, val in pairs(vim.lsp.protocol.CompletionItemKind) do
      if type(key) == "string" and type(val) == "number" then
        table.insert({label = key, kind = val})
      end
    end

    callback {
      isIncomplete = true, -- isIncomplete = True -> no caching
      items = items
    }
  end
end
