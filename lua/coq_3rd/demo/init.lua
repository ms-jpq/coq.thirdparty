return function(spec)
  return function(args, callback)
    local items = {}

    -- label :: text to insert if insertText = None
    -- kind  :: int ∈ `vim.lsp.protocol.CompletionItemKind`
    -- insertText :: string | None, text to insert

    for key, val in pairs(vim.lsp.protocol.CompletionItemKind) do
      if type(key) == "string" and type(val) == "number" then
        table.insert(items, {label = key, kind = val})
      end
    end

    callback {
      isIncomplete = true, -- isIncomplete = True -> no caching
      items = items
    }
  end
end
