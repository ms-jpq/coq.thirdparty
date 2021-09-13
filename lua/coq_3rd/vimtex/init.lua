local trans = require("coq_3rd.translate").completefunc

return function(spec)
  return function(args, callback)
    local matches =
      vim.fn["vimtex#complete#omnifunc"](0, vim.fn.expand("<cword>"))
    callback(trans(matches))
  end
end
