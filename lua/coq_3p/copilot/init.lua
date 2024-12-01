local utils = require("coq_3p.utils")

return function(spec)
  vim.api.nvim_err_writeln(
    [[Please update to latest version of coq.nvim. This functionality not part of coq.thirdparty package anymore it has been pulled into main.]]
  )
end
