local trans = require("coq_3rd.trans").completefunc

return function(spec)
  return function(args, callback)
    local row, col = unpack(args.pos)

    local pos = vim.fn["vimtex#complete#omnifunc"](1, "")
    if pos == -2 or pos == -3 then
      callback(nil)
    else
      local cword = (function()
        if pos < 0 or pos >= col then
          return vim.fn.expand("<cword>")
        else
          return vim.fn.expand("<cword>")
        end
      end)()
      local matches = vim.fn["vimtex#complete#omnifunc"](0, cword)
      local words = matches.words and matches.words or matches
      callback {isIncomplete = true, items = trans(words)}
    end
  end
end
