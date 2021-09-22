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

  local nil_cb = function(_, _, callback)
    callback(nil)
  end

  local store =
    (function()
    local items = {}

    return {
      clear = function()
        items = {}
      end,
      populate = function(lsp_items)
        vim.validate {lsp_items = {lsp_items, "table"}}
        for key, val in pairs(lsp_items) do
          vim.validate {key = {key, "number"}, val = {val, "table"}}
          local cmd = val.command or {}
          vim.validate {cmd = {cmd, "table"}}
          local uid = utils.new_uid(items)
          cmd.title = tostring(uid)
          val.command = cmd
          items[uid] = val
        end
      end,
      search = function(title)
        vim.validate {title = {title, "string"}}
        return items[tonumber(title)]
      end
    }
  end)()

  return function(name, cmp_source)
    local cont = function()
      COQsources = COQsources or {}
      vim.validate {
        COQsources = {COQsources, "table"},
        cmp_source = {cmp_source, "table"}
      }

      local is_available =
        utils.bind(
        cmp_source.is_available or utils.constantly(true),
        cmp_source
      )

      local complete = (function()
        local complete = utils.bind(cmp_source.complete or nil_cb, cmp_source)
        return function(_, args, callback)
          local new_cb = function(lsp_items)
            store.clear()
            if type(lsp_items) == "table" then
              if type(lsp_items.items) == "table" then
                store.populate(lsp_items.items)
              else
                store.populate(lsp_items)
              end
            end
            callback(lsp_items)
          end
          return complete(args, new_cb)
        end
      end)()

      local resolve = utils.bind(cmp_source.resolve or nil_cb, cmp_source)

      local exec = (function()
        local exec = utils.bind(cmp_source.execute or nil_cb, cmp_source)
        return function(_, args, callback)
          local item = store.search(args.title)
          if item then
            exec(item, callback)
          end
        end
      end)()

      COQsources[utils.new_uid(COQsources)] = {
        name = name,
        fn = function(args, callback)
          if not is_available() then
            callback(nil)
          else
            local cmp_args = trans(args)
            complete(cmp_args, callback)
          end
        end,
        resolve = function(args, callback)
          vim.validate {item = {args.item, "table"}}
          resolve(args.item, callback)
        end,
        exec = function(args, callback)
          vim.validate {
            command = {args.command, "string"},
            title = {args.title, "string"}
          }
          exec(args, callback)
        end
      }
    end

    local go, err = pcall(cont)
    if not go then
      vim.api.nvim_err_writeln(err)
    end
  end
end)()

M.lsp = vim.lsp.protocol

return utils.freeze("cmp", M)
