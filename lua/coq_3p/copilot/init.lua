return function(spec)
  local tmp_accept_key = spec.tmp_accept_key or "<c-r>"
  vim.validate {tmp_accept_key = {tmp_accept_key, "string"}}

  COQcopilot = function()
    return vim.fn["copilot#Accept"]() .. "\n"
  end

  vim.g.copilot_no_tab_map = true
  vim.g.copilot_assume_mapped = true
  vim.api.nvim_set_keymap(
    "i",
    tmp_accept_key,
    [[v:lua.COQcopilot()]],
    {nowait = true, silent = true, expr = true}
  )

  return function(args, callback)
    callback(nil)
  end
end
