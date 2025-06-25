local M = {}

-- 创建根节点
function M.create_root_node(root, hierarchy_item)
  return {
    id = 0,
    name = hierarchy_item.name or root.detail,
    filename = vim.fn.fnamemodify(root.file, ':t'),
    line = root.line,
    type = 'root',
    isDefinition = true,
    isRoot = true,
    size = 2.5,
    symbolKind = hierarchy_item.kind,
    detail = hierarchy_item.detail,
  }
end

-- 添加传入调用
function M.add_incoming_calls(chain_data, incoming_calls, root_id)
  if not incoming_calls or #incoming_calls == 0 then
    return
  end

  local base_id = #chain_data.nodes

  for i, incoming_call in ipairs(incoming_calls) do
    local node_id = base_id + i
    local caller = incoming_call.from

    local caller_node = {
      id = node_id,
      name = caller.name,
      filename = vim.fn.fnamemodify(vim.uri_to_fname(caller.uri), ':t'),
      line = caller.selectionRange.start.line + 1,
      type = 'incoming',
      isDefinition = false,
      isIncoming = true,
      size = 2.0,
      symbolKind = caller.kind,
      detail = caller.detail,
      call_count = #incoming_call.fromRanges,
    }

    table.insert(chain_data.nodes, caller_node)

    -- 添加边：从调用者指向根节点（表示调用关系）
    table.insert(chain_data.edges, {
      source = caller_node.id,
      target = root_id,
      type = 'incoming',
      call_count = caller_node.call_count,
    })
  end
end

-- 添加传出调用
function M.add_outgoing_calls(chain_data, outgoing_calls, root_id)
  if not outgoing_calls or #outgoing_calls == 0 then
    return
  end

  local base_id = #chain_data.nodes

  for i, outgoing_call in ipairs(outgoing_calls) do
    local node_id = base_id + i
    local callee = outgoing_call.to

    local callee_node = {
      id = node_id,
      name = callee.name,
      filename = vim.fn.fnamemodify(vim.uri_to_fname(callee.uri), ':t'),
      line = callee.selectionRange.start.line + 1,
      type = 'outgoing',
      isDefinition = false,
      isOutgoing = true,
      size = 2.0,
      symbolKind = callee.kind,
      detail = callee.detail,
      call_count = #outgoing_call.fromRanges,
    }

    table.insert(chain_data.nodes, callee_node)

    -- 添加边：从根节点指向被调用者
    table.insert(chain_data.edges, {
      source = root_id,
      target = callee_node.id,
      type = 'outgoing',
      call_count = callee_node.call_count,
    })
  end
end

-- 完善数据
function M.finalize_data(chain_data)
  local stats = {
    total_nodes = #chain_data.nodes,
    total_edges = #chain_data.edges,
    incoming_calls = 0,
    outgoing_calls = 0,
    root_function = nil,
    mode = chain_data.mode or 'unknown',
  }

  -- 计算统计信息
  for _, node in ipairs(chain_data.nodes) do
    if node.type == 'root' then
      stats.root_function = node.name
    elseif node.type == 'incoming' then
      stats.incoming_calls = stats.incoming_calls + 1
    elseif node.type == 'outgoing' then
      stats.outgoing_calls = stats.outgoing_calls + 1
    end
  end

  -- 按文件分组
  local files = {}
  for _, node in ipairs(chain_data.nodes) do
    local filename = node.filename
    if filename and not files[filename] then
      files[filename] = 0
    end
    if filename then
      files[filename] = files[filename] + 1
    end
  end

  return {
    nodes = chain_data.nodes,
    edges = chain_data.edges,
    summary = {
      root_function = stats.root_function or 'Unknown',
      total_nodes = stats.total_nodes,
      total_edges = stats.total_edges,
      incoming_calls = stats.incoming_calls,
      outgoing_calls = stats.outgoing_calls,
      files_involved = vim.tbl_count(files),
      mode = stats.mode,
    },
    metadata = {
      generated_at = os.date('%Y-%m-%d %H:%M:%S'),
      lsp_method = 'callHierarchy',
      mode = stats.mode,
    },
  }
end

-- 向后兼容的构建调用链函数
function M.build_call_chain(root, result)
  local nodes = {}
  local edges = {}
  local node_id = 0

  -- 添加定义节点
  local def_node = {
    id = node_id,
    name = root.detail,
    filename = vim.fn.fnamemodify(root.file, ':t'),
    line = root.line,
    type = 'root',
    isDefinition = true,
    size = 2.0,
  }
  table.insert(nodes, def_node)
  node_id = node_id + 1

  -- 添加引用节点
  for _, ref in ipairs(result) do
    local node = ref.from
    local ref_node = {
      id = node_id,
      name = node.name,
      filename = vim.fn.fnamemodify(vim.uri_to_fname(node.uri), ':t'),
      line = node.selectionRange.start.line + 1,
      type = 'incoming',
      isDefinition = false,
      isIncoming = true,
      size = 1.0,
    }
    table.insert(nodes, ref_node)

    -- 添加边
    table.insert(edges, {
      source = ref_node.id,
      target = def_node.id,
      value = 1,
      type = 'incoming',
    })

    node_id = node_id + 1
  end

  return {
    nodes = nodes,
    edges = edges,
    summary = {
      root_function = def_node.name,
      total_nodes = #nodes,
      total_edges = #edges,
      incoming_calls = #nodes - 1,
      outgoing_calls = 0,
      mode = 'incoming',
    },
  }
end

return M
