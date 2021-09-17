local utils = require("coq_3p.utils")

local M = {}

M.register_source =
  (function()
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
        local bufnr = vim.api.nvim_get_current_buf()
        local completeinfo =
          vim.fn.complete_info {"selected", "mode", "pum_visible"}
        args_cache =
          utils.freeze(
          "params",
          {
            offset = col,
            context = utils.freeze(
              "params.context",
              {
                bufnr = bufnr,
                cursor_after_line = rhs,
                cursor_before_line = lhs,
                cursor_line = args.line,
                cursor = utils.freeze(
                  "context.cursor",
                  {
                    row = row + 1,
                    col = col,
                    line = row
                  }
                ),
                filetype = vim.api.nvim_buf_get_option(bufnr, "filetype"),
                mode = vim.api.nvim_get_mode().mode,
                pumselect = completeinfo.selected ~= -1,
                pumvisible = completeinfo.pum_visible ~= 0,
                time = vim.loop.now(),
                virtcol = vim.fn.virtcol(".")
              }
            ),
            completion_context = utils.freeze(
              "params.context.completion_context",
              {
                triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked
              }
            )
          }
        )
        return args_cache
      end
    end
  end)()

  return function(name, cmp_source)
    local go, err =
      pcall(
      function()
        COQsources = COQsources or {}
        vim.validate {
          COQsources = {COQsources, "table"},
          cmp_source = {cmp_source, "table"}
        }

        COQsources[utils.new_uid(COQsources)] = {
          name = name,
          fn = function(args, callback)
            local cmp_args = trans(args)
            if
              not (cmp_source.is_available or utils.constantly(true))(
                cmp_source
              )
             then
              callback(nil)
            else
              local _ = (cmp_source.complete or function(_, args, callback)
                  callback(args)
                end)(cmp_source, cmp_args, callback)
            end
          end
        }
      end
    )
    if not go then
      vim.api.nvim_err_writeln(err)
    end
  end
end)()

M.lsp = vim.lsp.protocol

return utils.freeze("cmp", M)
