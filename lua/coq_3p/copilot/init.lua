return function(spec)
  vim.g.copilot_no_tab_map = true
  vim.g.copilot_assume_mapped = true
  vim.g.copilot_tab_fallback = ""

  return function(args, callback)
    callback(nil)
  end
  -- count to 20
end
