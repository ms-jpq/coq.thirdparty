-- Very simple case
-- Offers suggestions of `vim.lsp.protocol.CompletionItemKind`

return function(spec)
  return function(args, callback)
    local items = {}

    -- label      :: text to insert if insertText = None
    -- kind       :: int ∈ `vim.lsp.protocol.CompletionItemKind`
    -- insertText :: string | None, text to insert
    -- detail     :: doc popup

    for key, val in pairs(vim.lsp.protocol.CompletionItemKind) do
      if type(key) == "string" and type(val) == "number" then
        local item = {
          label = key,
          kind = val,
          detail = tostring(math.random())
        }
        table.insert(items, item)
      end
    end

    callback {
      isIncomplete = true, -- isIncomplete = True -> no caching
      items = items
    }
  end
end
