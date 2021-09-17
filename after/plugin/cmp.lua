local utils = require("coq_3p.utils")

local M = {}

local trans =
  (function()
  local session_id = -1
  local args_cache = nil

  return function(args)
    if session_id == args.uid and args_cache then
      return args_cache
    else
      local row, col = unpack(args.pos)
      local lhs, rhs = utils.split_line(args.line, col)
      args_cache = {
        offset = col,
        context = {cursor_before_line = lhs},
        ctx = {triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked}
      }
      return args_cache
    end
  end
end)()

M.register_source = function(name, cmp_source)
  COQsources = COQsources or {}
  vim.validate {
    COQsources = {COQsources, "table"}
  }

  local cont = function()
    vim.validate {cmp_source = {cmp_source, "table"}}
    local triggers = cmp_source:get_trigger_characters()
    for idx, char in ipairs(triggers) do
      vim.validate {idx = {idx, "number"}, char = {char, "string"}}
    end

    local go = function(before_cursor)
      for _, char in ipairs(triggers) do
        if vim.endswith(before_cursor, char) then
          return true
        end
      end
      return false
    end

    local coq_source = function(args, callback)
      if go(lhs) then
        callback(nil)
      else
        local cmp_args = trans(args)
        cmp_source:complete(cmp_args, callback)
      end
    end
  end

  local go, err = pcall(cont)
  if not go then
    vim.api.nvim_err_writeln(err)
  end
end

M.lsp = vim.lsp.protocol

return M
