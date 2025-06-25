local ms, api, lsp = vim.lsp.protocol.Methods, vim.api, vim.lsp
local M = {}
local server = require('visualizer.server')
local utils = require('visualizer.utils')
local INCOMING, OUTGOING, FULL = 1, 2, 3

local function request(client, bufnr, win, mode)
  local cursor_pos = api.nvim_win_get_cursor(win)
  local root = {
    detail = vim.fn.expand('<cword>'),
    line = cursor_pos[1],
    column = cursor_pos[2] + 1,
    file = api.nvim_buf_get_name(bufnr),
  }
  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)

  client:request(ms.textDocument_prepareCallHierarchy, params, function(err, result)
    if err or not result or next(result) == nil then
      vim.notify('No call hierarchy available', vim.log.levels.WARN)
      return
    end

    local hierarchy_item = result[1]
    local chain_data = { nodes = {}, edges = {}, mode = mode }

    local root_node = utils.create_root_node(root, hierarchy_item)
    table.insert(chain_data.nodes, root_node)

    local methods = {
      { ms.callHierarchy_incomingCalls },
      { ms.callHierarchy_outgoingCalls },
      { ms.callHierarchy_incomingCalls, ms.callHierarchy_outgoingCalls },
    }
    local add_method = { utils.add_incoming_calls, utils.add_outgoing_calls }

    local co
    co = coroutine.create(function()
      local results = {}
      for i, method in ipairs(methods[mode]) do
        ---@diagnostic disable-next-line: redefined-local
        client:request(method, { item = hierarchy_item }, function(err, res)
          local data = {}
          if not err and res and not vim.tbl_isempty(res) then
            data.result = res
          else
            data.err = err
          end
          coroutine.resume(co, data)
        end, bufnr)

        local data = coroutine.yield(co)
        if data.err then
          vim.schedule(function()
            vim.notify(data.err.message)
          end)
        else
          results[i] = data.result
        end

        if i == #methods[mode] then
          for idx, item in pairs(results) do
            add_method[idx](chain_data, item, root_node.id)
          end

          local final_data = utils.finalize_data(chain_data)
          server.send_data(final_data)
          vim.schedule(function()
            server.open()
          end)
        end
      end
    end)

    coroutine.resume(co)
  end, bufnr)
end

local function hierarchy(mode)
  local prepare_method = ms.textDocument_prepareCallHierarchy
  local bufnr = api.nvim_get_current_buf()
  local clients = lsp.get_clients({ bufnr = bufnr, method = prepare_method })
  if not next(clients) then
    vim.notify(lsp._unsupported_method(prepare_method), vim.log.levels.WARN)
    return
  end
  local win = api.nvim_get_current_win()

  if #clients == 1 then
    request(clients[1], bufnr, win, mode)
    return
  end

  local clients_map = {}
  for _, client in ipairs(clients) do
    clients_map[client.name] = client
  end

  vim.ui.select(vim.tbl_keys(clients_map), {
    prompt = 'Select a client:',
  }, function(choice)
    if not clients_map[choice] then
      return
    end
    request(clients_map[choice], bufnr, win, mode)
  end)
end

function M.show_incoming()
  server.start_server()
  vim.schedule(function()
    hierarchy(INCOMING)
  end)
end

function M.show_outgoing()
  server.start_server()
  vim.schedule(function()
    hierarchy(OUTGOING)
  end)
end

function M.show_full()
  server.start_server()
  vim.schedule(function()
    hierarchy(FULL)
  end)
end

return M
