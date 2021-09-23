local utils = require("coq_3p.utils")

return function()
  local sources =
    (function()
    local rtps = vim.api.nvim_list_runtime_paths()
    local pattern =
      table.concat(
      {"rplugin", "python3", "deoplete", "source", "*.py"},
      utils.sep
    )

    local acc = {}
    for _, rtp in ipairs(rtps) do
      local found = vim.fn.globpath(rtp, pattern, true, true)
      vim.list_extend(acc, found)
    end
    return acc
  end)()
end
