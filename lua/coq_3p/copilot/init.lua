return function(spec)
  vim.g.copilot_no_tab_map = true
  vim.g.copilot_assume_mapped = true
  vim.g.copilot_tab_fallback = ""
  vim.api.nvim_set_keymap(
    "i",
    "<a-l>",
    [[copilot#Accept()]],
    {nowait = true, silent = true, expr = true}
  )

  return function(args, callback)
    callback(nil)
  end
end
