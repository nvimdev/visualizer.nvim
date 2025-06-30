local M = {}

function M.create_root_node(root, hierarchy_item)
  local range = hierarchy_item.selectionRange or hierarchy_item.range
  local start_col = range and range.start.character or 0

  return {
    id = 0,
    name = hierarchy_item.name or root.detail,
    filename = vim.fn.fnamemodify(root.file, ':t'),
    filepath = root.file,
    line = root.line,
    column = start_col + 1,
    type = 'root',
    isDefinition = true,
    isRoot = true,
    size = 2.5,
    symbolKind = hierarchy_item.kind,
    detail = hierarchy_item.detail,
  }
end

function M.add_incoming_calls(chain_data, incoming_calls, root_id)
  if not incoming_calls or #incoming_calls == 0 then
    return
  end

  local base_id = #chain_data.nodes

  for i, incoming_call in ipairs(incoming_calls) do
    local node_id = base_id + i
    local caller = incoming_call.from

    local range = caller.selectionRange or caller.range
    local start_col = range and range.start.character or 0
    local filepath = vim.uri_to_fname(caller.uri)

    local caller_node = {
      id = node_id,
      name = caller.name,
      filename = vim.fn.fnamemodify(filepath, ':t'),
      filepath = filepath,
      line = caller.selectionRange.start.line + 1,
      column = start_col + 1,
      type = 'incoming',
      isDefinition = false,
      isIncoming = true,
      size = 2.0,
      symbolKind = caller.kind,
      detail = caller.detail,
      call_count = #incoming_call.fromRanges,
    }

    table.insert(chain_data.nodes, caller_node)

    table.insert(chain_data.edges, {
      source = caller_node.id,
      target = root_id,
      type = 'incoming',
      call_count = caller_node.call_count,
    })
  end
end

function M.add_outgoing_calls(chain_data, outgoing_calls, root_id)
  if not outgoing_calls or #outgoing_calls == 0 then
    return
  end

  local base_id = #chain_data.nodes

  for i, outgoing_call in ipairs(outgoing_calls) do
    local node_id = base_id + i
    local callee = outgoing_call.to

    -- 提取位置信息
    local range = callee.selectionRange or callee.range
    local start_col = range and range.start.character or 0
    local filepath = vim.uri_to_fname(callee.uri)

    local callee_node = {
      id = node_id,
      name = callee.name,
      filename = vim.fn.fnamemodify(filepath, ':t'),
      filepath = filepath, -- 完整路径
      line = callee.selectionRange.start.line + 1,
      column = start_col + 1, -- 转换为1基索引
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

-- LSP符号类型到星球类型的映射
local SYMBOL_KIND_MAP = {
  [1] = { name = 'File', size = 1.0, color = 0x8e44ad, type = 'file' },
  [2] = { name = 'Module', size = 2.5, color = 0xe74c3c, type = 'module' },
  [3] = { name = 'Namespace', size = 2.0, color = 0x3498db, type = 'namespace' },
  [4] = { name = 'Package', size = 3.0, color = 0x2ecc71, type = 'package' },
  [5] = { name = 'Class', size = 2.5, color = 0xf39c12, type = 'class' },
  [6] = { name = 'Method', size = 1.5, color = 0x9b59b6, type = 'method' },
  [7] = { name = 'Property', size = 0.8, color = 0x1abc9c, type = 'property' },
  [8] = { name = 'Field', size = 0.8, color = 0x34495e, type = 'field' },
  [9] = { name = 'Constructor', size = 1.8, color = 0xe67e22, type = 'constructor' },
  [10] = { name = 'Enum', size = 1.5, color = 0x95a5a6, type = 'enum' },
  [11] = { name = 'Interface', size = 2.0, color = 0x16a085, type = 'interface' },
  [12] = { name = 'Function', size = 1.5, color = 0x2980b9, type = 'function' },
  [13] = { name = 'Variable', size = 0.6, color = 0x27ae60, type = 'variable' },
  [14] = { name = 'Constant', size = 0.8, color = 0xf1c40f, type = 'constant' },
  [15] = { name = 'String', size = 0.5, color = 0xe8c547, type = 'string' },
  [16] = { name = 'Number', size = 0.5, color = 0x52c41a, type = 'number' },
  [17] = { name = 'Boolean', size = 0.5, color = 0x722ed1, type = 'boolean' },
  [18] = { name = 'Array', size = 1.0, color = 0xfa541c, type = 'array' },
  [19] = { name = 'Object', size = 1.2, color = 0x13c2c2, type = 'object' },
  [20] = { name = 'Key', size = 0.4, color = 0xeb2f96, type = 'key' },
  [21] = { name = 'Null', size = 0.3, color = 0x666666, type = 'null' },
  [22] = { name = 'EnumMember', size = 0.7, color = 0xa0d911, type = 'enum_member' },
  [23] = { name = 'Struct', size = 2.0, color = 0xff7a45, type = 'struct' },
  [24] = { name = 'Event', size = 1.0, color = 0xffc53d, type = 'event' },
  [25] = { name = 'Operator', size = 0.8, color = 0x40a9ff, type = 'operator' },
  [26] = { name = 'TypeParameter', size = 1.0, color = 0xb37feb, type = 'type_parameter' },
}

-- 创建星系数据结构
function M.create_galaxy(workspace_symbols)
  local galaxy_data = {
    nodes = {},
    star_systems = {},
    type = 'galaxy',
    mode = 'galaxy',
  }

  -- 按文件分组符号，创建星系结构
  local files = {}
  local file_symbol_counts = {}

  for i, symbol in ipairs(workspace_symbols) do
    local filepath = vim.uri_to_fname(symbol.location.uri)
    local filename = vim.fn.fnamemodify(filepath, ':t')
    local file_key = filepath

    if not files[file_key] then
      files[file_key] = {
        filepath = filepath,
        filename = filename,
        symbols = {},
        importance = 0,
      }
      file_symbol_counts[file_key] = 0
    end

    -- 计算符号的重要性
    local symbol_info = SYMBOL_KIND_MAP[symbol.kind] or SYMBOL_KIND_MAP[12] -- 默认为函数
    local importance = symbol_info.size

    -- 根据符号名称长度和位置调整重要性
    local name_factor = math.min(#symbol.name / 10, 2)
    importance = importance * (1 + name_factor * 0.3)

    local range = symbol.location.range
    local line = range.start.line + 1
    local column = range.start.character + 1

    local star_node = {
      id = i - 1,
      name = symbol.name,
      filename = filename,
      filepath = filepath,
      line = line,
      column = column,
      type = 'star',
      symbolKind = symbol.kind,
      symbolType = symbol_info.type,
      symbolName = symbol_info.name,
      size = importance,
      color = symbol_info.color,
      importance = importance,
      containerName = symbol.containerName,
      detail = symbol.detail or symbol_info.name,
      file_key = file_key,
    }

    table.insert(files[file_key].symbols, star_node)
    table.insert(galaxy_data.nodes, star_node)
    files[file_key].importance = files[file_key].importance + importance
    file_symbol_counts[file_key] = file_symbol_counts[file_key] + 1
  end

  -- 创建星系系统（每个文件是一个星系系统）
  local system_id = 0
  for file_key, file_data in pairs(files) do
    system_id = system_id + 1

    -- 计算星系系统的大小和重要性
    local symbol_count = file_symbol_counts[file_key]
    local avg_importance = file_data.importance / math.max(symbol_count, 1)
    local system_size = math.min(math.max(symbol_count / 5, 1), 10)

    local star_system = {
      id = system_id,
      name = file_data.filename,
      filepath = file_data.filepath,
      symbol_count = symbol_count,
      total_importance = file_data.importance,
      average_importance = avg_importance,
      size = system_size,
      type = 'star_system',
      symbols = file_data.symbols,
      center = { x = 0, y = 0, z = 0 }, -- 将在前端计算
      radius = system_size * 15, -- 星系系统半径
    }

    -- 为星系系统中的每个符号分配相对位置
    for j, symbol in ipairs(file_data.symbols) do
      symbol.system_id = system_id
      symbol.local_index = j
    end

    table.insert(galaxy_data.star_systems, star_system)
  end

  return M.finalize_galaxy_data(galaxy_data)
end

-- 完善星系数据
function M.finalize_galaxy_data(galaxy_data)
  local stats = {
    total_stars = #galaxy_data.nodes,
    total_systems = #galaxy_data.star_systems,
    largest_system = nil,
    most_important_star = nil,
    symbol_types = {},
  }

  -- 统计信息
  local max_system_size = 0
  local max_star_importance = 0

  for _, system in ipairs(galaxy_data.star_systems) do
    if system.symbol_count > max_system_size then
      max_system_size = system.symbol_count
      stats.largest_system = system.name
    end
  end

  for _, star in ipairs(galaxy_data.nodes) do
    if star.importance > max_star_importance then
      max_star_importance = star.importance
      stats.most_important_star = star.name
    end

    local symbol_type = star.symbolName or 'Unknown'
    stats.symbol_types[symbol_type] = (stats.symbol_types[symbol_type] or 0) + 1
  end

  return {
    nodes = galaxy_data.nodes,
    star_systems = galaxy_data.star_systems,
    type = 'galaxy',
    mode = 'galaxy',
    summary = {
      total_stars = stats.total_stars,
      total_systems = stats.total_systems,
      largest_system = stats.largest_system,
      most_important_star = stats.most_important_star,
      galaxy_name = 'Code Galaxy',
      exploration_mode = '3D Space Flight',
    },
    metadata = {
      generated_at = os.date('%Y-%m-%d %H:%M:%S'),
      lsp_method = 'workspace/symbol',
      visualization_type = 'galaxy',
      symbol_types = stats.symbol_types,
    },
  }
end

-- 完善数据（原有函数）
function M.finalize_data(chain_data)
  local stats = {
    total_nodes = #chain_data.nodes,
    total_edges = #chain_data.edges,
    incoming_calls = 0,
    outgoing_calls = 0,
    root_function = nil,
    mode = chain_data.mode or 'unknown',
  }

  for _, node in ipairs(chain_data.nodes) do
    if node.type == 'root' then
      stats.root_function = node.name
    elseif node.type == 'incoming' then
      stats.incoming_calls = stats.incoming_calls + 1
    elseif node.type == 'outgoing' then
      stats.outgoing_calls = stats.outgoing_calls + 1
    end
  end

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

return M
