local M = {}
local uv = vim.uv
local server = nil
local url = nil
local data_to_visualize = nil

local function get_assets_dir()
  local script_path = debug.getinfo(1, 'S').source:sub(2)
  local _, e = script_path:find('%.nvim')
  return script_path:sub(1, e)
end

local function handle_open_file(client, request_body)
  local success, data = pcall(vim.json.decode, request_body)
  if not success or not data then
    uv.write(client, 'HTTP/1.1 400 Bad Request\r\n\r\n{"error": "Invalid JSON"}')
    return
  end

  local filepath = data.filepath
  local line = data.line or 1
  local column = data.column or 1

  if not filepath then
    uv.write(client, 'HTTP/1.1 400 Bad Request\r\n\r\n{"error": "No filepath provided"}')
    return
  end

  vim.schedule(function()
    if vim.fn.filereadable(filepath) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
      vim.api.nvim_win_set_cursor(0, { line, column - 1 })
      vim.cmd('normal! zz')
      vim.notify(
        string.format('Opened %s at line %d, column %d', vim.fn.fnamemodify(filepath, ':t'), line, column),
        vim.log.levels.INFO
      )
    else
      vim.notify('File not found: ' .. filepath, vim.log.levels.ERROR)
    end
  end)

  local response = vim.json.encode({ success = true, message = 'File opened' })
  uv.write(client, {
    'HTTP/1.1 200 OK\r\n',
    'Content-Type: application/json\r\n',
    'Access-Control-Allow-Origin: *\r\n',
    'Content-Length: ' .. #response .. '\r\n',
    '\r\n',
    response,
  })
end

function M.start_server(html_func)
  if server and not server:is_closing() then
    server:close()
    server = nil
    url = nil
  end

  server = assert(uv.new_tcp())
  uv.tcp_bind(server, '127.0.0.1', 0)
  uv.listen(server, 128, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    uv.accept(server, client)

    local request_data = ''

    uv.read_start(client, function(err, chunk)
      if err then
        uv.close(client)
        return
      end
      if chunk then
        request_data = request_data .. chunk

        local headers_end = request_data:find('\r\n\r\n')
        if headers_end then
          local headers = request_data:sub(1, headers_end - 1)
          local body = request_data:sub(headers_end + 4)

          if headers:match('GET /assets/') then
            local path = headers:match('GET (/assets/[^%s]+)')
            if path then
              local assets_dir = get_assets_dir()
              local file_path = assets_dir .. '/assets/three.min.js'
              local file = io.open(file_path, 'rb')
              if file then
                local content = file:read('*a')
                file:close()

                local content_type = 'application/javascript'
                if file_path:match('%.css$') then
                  content_type = 'text/css'
                elseif file_path:match('%.html$') then
                  content_type = 'text/html'
                end

                uv.write(client, {
                  'HTTP/1.1 200 OK\r\n',
                  'Content-Type: ' .. content_type .. '\r\n',
                  'Content-Length: ' .. #content .. '\r\n',
                  '\r\n',
                  content,
                })
              else
                uv.write(client, 'HTTP/1.1 404 Not Found\r\n\r\n')
              end
            else
              uv.write(client, 'HTTP/1.1 404 Not Found\r\n\r\n')
            end
          elseif headers:match('POST /open%-file') then
            local content_length = headers:match('Content%-Length: (%d+)')
            if content_length then
              local expected_length = tonumber(content_length)
              if #body >= expected_length then
                handle_open_file(client, body:sub(1, expected_length))
              else
                return
              end
            else
              handle_open_file(client, body)
            end
          elseif headers:match('GET /') then
            local html = html_func and html_func(data_to_visualize) or M.get_html()
            uv.write(client, {
              'HTTP/1.1 200 OK\r\n',
              'Content-Type: text/html\r\n',
              'Content-Length: ' .. #html .. '\r\n',
              '\r\n',
              html,
            })
          else
            uv.write(client, 'HTTP/1.1 404 Not Found\r\n\r\n')
          end
          uv.close(client)
        end
      end
    end)
  end)

  url = 'http://localhost:' .. server:getsockname().port
  vim.notify('Server started at ' .. url)
end

function M.get_html()
  local json_data = data_to_visualize and vim.json.encode(data_to_visualize) or '{}'

  local html = [[
    <!DOCTYPE html>
    <html>
    <head>
        <title>LSP Call Chain Visualizer</title>
        <style>
            body { 
                margin: 0; 
                background: linear-gradient(135deg, #0f0f23, #1a1a3e, #2d1b69);
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                overflow: hidden;
            }
            #info {
                position: absolute;
                top: 15px;
                width: 100%;
                text-align: center;
                color: #e0e0e0;
                font-family: 'Courier New', monospace;
                pointer-events: none;
                font-size: 14px;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
                line-height: 1.4;
                z-index: 1000;
            }
            #controls {
                position: absolute;
                bottom: 20px;
                left: 20px;
                background: rgba(15, 15, 35, 0.95);
                padding: 15px;
                border-radius: 12px;
                color: white;
                font-family: sans-serif;
                backdrop-filter: blur(15px);
                border: 1px solid rgba(255, 255, 255, 0.1);
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
                z-index: 1000;
            }
            #controls button {
                background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
                border: none;
                color: white;
                padding: 10px 16px;
                margin: 5px;
                border-radius: 8px;
                cursor: pointer;
                transition: all 0.3s ease;
                font-weight: 500;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            }
            #controls button:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
            }
            #controls button:active {
                transform: translateY(0);
            }
            #controls label {
                margin-left: 10px;
                cursor: pointer;
                font-size: 13px;
                color: #b0b0b0;
            }
            #controls input[type="range"] {
                width: 120px;
                margin-left: 8px;
            }
            #legend {
                position: absolute;
                top: 20px;
                right: 20px;
                background: rgba(15, 15, 35, 0.95);
                padding: 15px;
                border-radius: 12px;
                color: white;
                font-family: sans-serif;
                font-size: 12px;
                backdrop-filter: blur(15px);
                border: 1px solid rgba(255, 255, 255, 0.1);
                z-index: 1000;
            }
            .legend-item {
                display: flex;
                align-items: center;
                margin: 5px 0;
            }
            .legend-color {
                width: 16px;
                height: 16px;
                border-radius: 50%;
                margin-right: 8px;
            }
            .legend-root { background: #FF6B6B; }
            .legend-incoming { background: #4fc3f7; }
            .legend-outgoing { background: #66bb6a; }
            .legend-visited { background: #ffd700; }
        </style>
    </head>
    <body>
        <div id="info">LSP Call Chain Visualization<br><span id="summary"></span></div>
        <div id="legend">
            <div><strong>Legend</strong></div>
            <div class="legend-item">
                <div class="legend-color legend-root"></div>
                <span>Current Function</span>
            </div>
            <div class="legend-item">
                <div class="legend-color legend-incoming"></div>
                <span>Callers (Incoming)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color legend-outgoing"></div>
                <span>Called Functions (Outgoing)</span>
            </div>
            <div class="legend-item">
                <div class="legend-color legend-visited"></div>
                <span>Visited Nodes</span>
            </div>
            <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.2);">
                <div><strong>Flow Effects</strong></div>
                <div style="font-size: 11px; color: #4fc3f7; margin: 2px 0;">● Blue particles: Incoming calls</div>
                <div style="font-size: 11px; color: #66bb6a; margin: 2px 0;">● Green particles: Outgoing calls</div>
                <div style="font-size: 11px; color: #aaa; margin: 2px 0;">Speed = Call frequency</div>
            </div>
        </div>
        <div id="controls">
            <button id="resetView">Reset View</button>
            <button id="togglePhysics">Pause Physics</button>
            <button id="clearVisited">Clear Visited</button>
            <label>
                <input type="checkbox" id="showLabels" checked> Show Labels
            </label>
            <label>
                <input type="checkbox" id="showFlowingParticles" checked> Flow Effects
            </label>
            <br>
            <label>Force Strength: <input type="range" id="forceStrength" min="0.1" max="3" step="0.1" value="1"></label>
            <label>Flow Speed: <input type="range" id="flowSpeed" min="0.1" max="3" step="0.1" value="1"></label>
        </div>

        <script>
            function handleThreeJSLoadError() {
                console.error('Failed to load Three.js from /assets/three.min.js');
                document.getElementById('summary').textContent = 'Failed to load 3D visualization library';
                const script = document.createElement('script');
                script.src = 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js';
                script.onload = () => {
                    console.log('Three.js loaded from CDN');
                    waitForThree(() => init());
                };
                script.onerror = () => {
                    console.error('Failed to load Three.js from CDN as well');
                    document.getElementById('summary').textContent = 'Error: Cannot load 3D visualization';
                };
                document.head.appendChild(script);
            }

            function loadThreeJS() {
                const script = document.createElement('script');
                script.src = '/assets/three.min.js';
                script.onload = () => {
                    console.log('Three.js loaded successfully');
                    if (typeof THREE !== 'undefined') {
                        init();
                    } else {
                        waitForThree(() => init());
                    }
                };
                script.onerror = handleThreeJSLoadError;
                document.head.appendChild(script);
            }

            function waitForThree(callback) {
                if (typeof THREE !== 'undefined') {
                    callback();
                } else {
                    setTimeout(() => waitForThree(callback), 50);
                }
            }

            const LSP_DATA = ]] .. json_data .. [[;

            let scene, camera, renderer;
            let nodes = [], edges = [];
            let nodeMeshes = [], edgeLines = [], labels = [];
            let flowingParticles = [];
            let raycaster, mouse;
            let selectedNode = null;
            let physicsEnabled = true;
            let showLabels = true;
            let showFlowingParticles = true;
            let flowSpeed = 1.0;
            let forceStrength = 1.0;
            let visitedNodes = new Set();

            const REPULSION_FORCE = 80;
            const SPRING_FORCE = 0.08;
            const DAMPING = 0.85;
            const CENTER_FORCE = 0.015;

            let nodePhysics = [];

            function init() {
                if (typeof THREE === 'undefined') {
                    console.error('THREE.js is not loaded');
                    return;
                }

                try {
                    scene = new THREE.Scene();
                    scene.background = new THREE.Color(0x0a0a1a);

                    camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
                    camera.position.set(0, 0, 35);

                    renderer = new THREE.WebGLRenderer({ antialias: true });
                    renderer.setSize(window.innerWidth, window.innerHeight);
                    renderer.setClearColor(0x0a0a1a);
                    document.body.appendChild(renderer.domElement);

                    raycaster = new THREE.Raycaster();
                    mouse = new THREE.Vector2();

                    const ambientLight = new THREE.AmbientLight(0x404040, 1.0);
                    scene.add(ambientLight);

                    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
                    directionalLight.position.set(20, 20, 20);
                    scene.add(directionalLight);

                    const fillLight = new THREE.DirectionalLight(0x4466ff, 0.3);
                    fillLight.position.set(-20, -20, -20);
                    scene.add(fillLight);

                    setupCameraControls();
                    fetchData();

                    window.addEventListener('resize', onWindowResize, false);
                    window.addEventListener('mousemove', onMouseMove, false);
                    window.addEventListener('click', onMouseClick, false);

                    document.getElementById('resetView').addEventListener('click', resetCamera);
                    document.getElementById('togglePhysics').addEventListener('click', togglePhysics);
                    document.getElementById('clearVisited').addEventListener('click', clearVisited);
                    document.getElementById('showLabels').addEventListener('change', function(e) {
                        showLabels = e.target.checked;
                        updateLabelsVisibility();
                    });
                    document.getElementById('showFlowingParticles').addEventListener('change', function(e) {
                        showFlowingParticles = e.target.checked;
                        updateFlowingParticlesVisibility();
                    });
                    document.getElementById('forceStrength').addEventListener('input', function(e) {
                        forceStrength = parseFloat(e.target.value);
                    });
                    document.getElementById('flowSpeed').addEventListener('input', function(e) {
                        flowSpeed = parseFloat(e.target.value);
                    });

                    animate();
                } catch (error) {
                    console.error('Error initializing Three.js scene:', error);
                    document.getElementById('summary').textContent = 'Error loading 3D visualization';
                }
            }

            function clearVisited() {
                visitedNodes.clear();
                resetNodeColors();
                const summaryElement = document.getElementById('summary');
                if (summaryElement) {
                    document.getElementById('info').innerHTML = 
                        'LSP Call Chain Visualization<br><span id="summary">' + 
                        summaryElement.textContent + '</span>';
                }
            }

            function openFile(node) {
                if (!node.filepath) {
                    console.error('No filepath available for node:', node);
                    return;
                }

                const requestData = {
                    filepath: node.filepath,
                    line: node.line || 1,
                    column: node.column || 1
                };

                fetch('/open-file', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(requestData)
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        console.log('File opened successfully:', node.filepath);
                    } else {
                        console.error('Failed to open file:', data.error);
                    }
                })
                .catch(error => {
                    console.error('Error opening file:', error);
                });
            }

            let isDragging = false;
            let previousMousePosition = { x: 0, y: 0 };
            let cameraAngleY = 0;
            let cameraAngleX = 0;

            function setupCameraControls() {
                renderer.domElement.addEventListener('mousedown', function(e) {
                    isDragging = true;
                    previousMousePosition = { x: e.clientX, y: e.clientY };
                });

                renderer.domElement.addEventListener('mouseup', function() {
                    isDragging = false;
                });

                renderer.domElement.addEventListener('mousemove', function(e) {
                    if (isDragging) {
                        const deltaX = e.clientX - previousMousePosition.x;
                        const deltaY = e.clientY - previousMousePosition.y;

                        cameraAngleY += deltaX * 0.01;
                        cameraAngleX += deltaY * 0.01;
                        cameraAngleX = Math.max(-Math.PI/2, Math.min(Math.PI/2, cameraAngleX));

                        updateCameraPosition();
                        previousMousePosition = { x: e.clientX, y: e.clientY };
                    }
                });

                renderer.domElement.addEventListener('wheel', function(e) {
                    const scale = e.deltaY > 0 ? 1.1 : 0.9;
                    camera.position.multiplyScalar(scale);
                    camera.position.z = Math.max(5, Math.min(100, camera.position.z));
                });
            }

            function updateCameraPosition() {
                const radius = 35;
                camera.position.x = Math.sin(cameraAngleY) * Math.cos(cameraAngleX) * radius;
                camera.position.y = Math.sin(cameraAngleX) * radius;
                camera.position.z = Math.cos(cameraAngleY) * Math.cos(cameraAngleX) * radius;
                camera.lookAt(0, 0, 0);
            }

            function fetchData() {
                const data = LSP_DATA;

                if (!data || !data.nodes) {
                    document.getElementById('summary').textContent = 'No data to visualize';
                    return;
                }

                if (data.summary) {
                    let summaryText = `Function: ${data.summary.root_function}`;
                    if (data.summary.mode) {
                        summaryText += ` | Mode: ${data.summary.mode}`;
                    }
                    if (data.summary.incoming_calls > 0) {
                        summaryText += ` | Incoming: ${data.summary.incoming_calls}`;
                    }
                    if (data.summary.outgoing_calls > 0) {
                        summaryText += ` | Outgoing: ${data.summary.outgoing_calls}`;
                    }
                    document.getElementById('summary').textContent = summaryText;
                } else {
                    document.getElementById('summary').textContent = 
                        `Nodes: ${data.nodes.length} | Edges: ${data.edges ? data.edges.length : 0}`;
                }

                clearScene();
                nodes = data.nodes;
                edges = data.edges || [];

                physicsEnabled = true;
                document.getElementById('togglePhysics').textContent = 'Pause Physics';

                initNodePhysics();
                createNodes();
                createEdges();
                initialLayout();
            }

            function clearScene() {
                nodeMeshes.forEach(mesh => scene.remove(mesh));
                edgeLines.forEach(line => scene.remove(line));
                labels.forEach(label => scene.remove(label));

                flowingParticles.forEach(group => {
                    group.particles.forEach(particle => scene.remove(particle));
                });

                nodeMeshes = [];
                edgeLines = [];
                labels = [];
                flowingParticles = [];
                nodePhysics = [];
            }

            function initNodePhysics() {
                nodePhysics = nodes.map(() => ({
                    x: (Math.random() - 0.5) * 20,
                    y: (Math.random() - 0.5) * 20,
                    z: (Math.random() - 0.5) * 20,
                    vx: 0, vy: 0, vz: 0,
                    fx: 0, fy: 0, fz: 0
                }));
            }

            function createNodes() {
                nodes.forEach((node, index) => {
                    let geometry, color, emissiveColor, size;
                    size = node.size || 1.5;

                    if (node.type === 'root' || node.isDefinition) {
                        geometry = new THREE.OctahedronGeometry(size, 0);
                        color = 0xffd700;
                        emissiveColor = 0x443300;
                    } else if (node.type === 'incoming' || node.isIncoming) {
                        geometry = new THREE.SphereGeometry(size * 0.8, 20, 20);
                        color = 0x4fc3f7;
                        emissiveColor = 0x113344;
                    } else if (node.type === 'outgoing' || node.isOutgoing) {
                        geometry = new THREE.BoxGeometry(size * 1.2, size * 1.2, size * 1.2);
                        color = 0x66bb6a;
                        emissiveColor = 0x224422;
                    } else {
                        geometry = new THREE.SphereGeometry(size * 0.8, 20, 20);
                        color = 0x4ecdc4;
                        emissiveColor = 0x113344;
                    }

                    const material = new THREE.MeshPhongMaterial({ 
                        color: color,
                        emissive: emissiveColor,
                        shininess: 80,
                        transparent: true,
                        opacity: 0.95
                    });

                    const mesh = new THREE.Mesh(geometry, material);
                    mesh.position.set(
                        nodePhysics[index].x,
                        nodePhysics[index].y,
                        nodePhysics[index].z
                    );
                    mesh.userData = { node: node, index: index };

                    scene.add(mesh);
                    nodeMeshes.push(mesh);

                    addLabel(mesh, node, index);
                });
            }

            function createEdges() {
                edges.forEach(edge => {
                    const sourceIndex = nodes.findIndex(n => n.id === edge.source);
                    const targetIndex = nodes.findIndex(n => n.id === edge.target);

                    if (sourceIndex !== -1 && targetIndex !== -1) {
                        const material = new THREE.LineBasicMaterial({
                            color: 0x95a5a6,
                            transparent: true,
                            opacity: 0.6
                        });

                        const geometry = new THREE.BufferGeometry();
                        const positions = new Float32Array(6);
                        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

                        const line = new THREE.Line(geometry, material);
                        line.userData = { sourceIndex, targetIndex, type: edge.type };
                        scene.add(line);
                        edgeLines.push(line);

                        addArrow(sourceIndex, targetIndex, edge.type);

                        createFlowingParticles(sourceIndex, targetIndex, edge);
                    }
                });
            }

            function addArrow(sourceIndex, targetIndex, edgeType) {
                const arrowGeometry = new THREE.ConeGeometry(0.3, 1, 6);
                const arrowMaterial = new THREE.MeshPhongMaterial({
                    color: 0x95a5a6,
                    transparent: true,
                    opacity: 0.8
                });
                const arrow = new THREE.Mesh(arrowGeometry, arrowMaterial);
                arrow.userData = { sourceIndex, targetIndex, isArrow: true, edgeType };
                scene.add(arrow);
                edgeLines.push(arrow);
            }

            function createFlowingParticles(sourceIndex, targetIndex, edge) {
                const callCount = edge.call_count || 1;
                const edgeType = edge.type;

                const particleCount = Math.min(Math.max(callCount, 1), 5);

                let particleColor, flowDirection;
                if (edgeType === 'incoming') {
                    particleColor = 0x4fc3f7; // blue - from caller to current
                    flowDirection = 1;
                } else if (edgeType === 'outgoing') {
                    particleColor = 0x66bb6a; // green - from current to callee
                    flowDirection = 1;
                } else {
                    particleColor = 0xffd700;
                    flowDirection = 1;
                }

                const particleGroup = {
                    sourceIndex,
                    targetIndex,
                    edgeType,
                    particles: [],
                    speed: 0.01 + (callCount * 0.005), // speed
                    flowDirection
                };

                for (let i = 0; i < particleCount; i++) {
                    const particleGeometry = new THREE.SphereGeometry(0.15, 8, 8);
                    const particleMaterial = new THREE.MeshBasicMaterial({
                        color: particleColor,
                        transparent: true,
                        opacity: 0.8,
                        emissive: particleColor,
                        emissiveIntensity: 0.3
                    });

                    const particle = new THREE.Mesh(particleGeometry, particleMaterial);

                    const initialProgress = i / particleCount;
                    particle.userData = {
                        progress: initialProgress,
                        initialProgress: initialProgress,
                        sourceIndex,
                        targetIndex,
                        speed: particleGroup.speed,
                        flowDirection
                    };

                    scene.add(particle);
                    particleGroup.particles.push(particle);
                }

                flowingParticles.push(particleGroup);
            }

            function updateFlowingParticlesVisibility() {
                flowingParticles.forEach(group => {
                    group.particles.forEach(particle => {
                        particle.visible = showFlowingParticles;
                    });
                });
            }

            function updateFlowingParticles() {
                if (!showFlowingParticles) return;

                flowingParticles.forEach(group => {
                    const sourcePos = new THREE.Vector3(
                        nodePhysics[group.sourceIndex].x,
                        nodePhysics[group.sourceIndex].y,
                        nodePhysics[group.sourceIndex].z
                    );
                    const targetPos = new THREE.Vector3(
                        nodePhysics[group.targetIndex].x,
                        nodePhysics[group.targetIndex].y,
                        nodePhysics[group.targetIndex].z
                    );

                    group.particles.forEach(particle => {
                        const adjustedSpeed = particle.userData.speed * flowSpeed;
                        particle.userData.progress += adjustedSpeed * particle.userData.flowDirection;

                        if (particle.userData.progress > 1) {
                            particle.userData.progress = 0;
                        } else if (particle.userData.progress < 0) {
                            particle.userData.progress = 1;
                        }

                        const progress = particle.userData.progress;
                        particle.position.lerpVectors(sourcePos, targetPos, progress);

                        const time = Date.now() * 0.003;
                        const floatOffset = Math.sin(time + particle.userData.initialProgress * Math.PI * 2) * 0.2;
                        particle.position.y += floatOffset;

                        const intensity = 0.3 + (adjustedSpeed * 20);
                        particle.material.emissiveIntensity = Math.min(intensity, 0.8);

                        const fadeProgress = Math.abs(0.5 - progress) * 2;
                        particle.material.opacity = 0.4 + fadeProgress * 0.4;

                        if (selectedNode) {
                            const sourceNode = nodes[group.sourceIndex];
                            const targetNode = nodes[group.targetIndex];
                            if (sourceNode.id === selectedNode.id || targetNode.id === selectedNode.id) {
                                particle.scale.set(1.5, 1.5, 1.5);
                                particle.material.emissiveIntensity = Math.min(intensity * 1.5, 1.0);
                            } else {
                                particle.scale.set(1, 1, 1);
                            }
                        } else {
                            particle.scale.set(1, 1, 1);
                        }
                    });
                });
            }

            function addLabel(mesh, node, index) {
                const canvas = document.createElement('canvas');
                const context = canvas.getContext('2d');
                canvas.width = 420;
                canvas.height = 120;

                const gradient = context.createLinearGradient(0, 0, canvas.width, canvas.height);
                if (node.type === 'root' || node.isDefinition) {
                    gradient.addColorStop(0, 'rgba(255, 107, 107, 0.9)');
                    gradient.addColorStop(1, 'rgba(200, 60, 60, 0.9)');
                } else if (node.type === 'incoming' || node.isIncoming) {
                    gradient.addColorStop(0, 'rgba(79, 195, 247, 0.9)');
                    gradient.addColorStop(1, 'rgba(41, 154, 204, 0.9)');
                } else if (node.type === 'outgoing' || node.isOutgoing) {
                    gradient.addColorStop(0, 'rgba(102, 187, 106, 0.9)');
                    gradient.addColorStop(1, 'rgba(67, 160, 71, 0.9)');
                } else {
                    gradient.addColorStop(0, 'rgba(78, 205, 196, 0.9)');
                    gradient.addColorStop(1, 'rgba(50, 160, 150, 0.9)');
                }

                context.fillStyle = gradient;
                context.fillRect(0, 0, canvas.width, canvas.height);

                context.strokeStyle = 'rgba(255, 255, 255, 0.4)';
                context.lineWidth = 2;
                context.strokeRect(1, 1, canvas.width - 2, canvas.height - 2);

                context.fillStyle = 'white';
                context.textAlign = 'center';
                context.shadowColor = 'rgba(0, 0, 0, 0.8)';
                context.shadowBlur = 4;
                
                context.font = 'bold 24px Arial';
                context.fillText(node.name, canvas.width / 2, 32);
                
                context.font = '16px Arial';
                context.fillStyle = 'rgba(255, 255, 255, 0.9)';
                let subtitle = '';
                if (node.type === 'root') {
                    subtitle = 'Current Function';
                } else if (node.type === 'incoming') {
                    subtitle = node.call_count ? `Caller (${node.call_count} calls)` : 'Caller';
                } else if (node.type === 'outgoing') {
                    subtitle = node.call_count ? `Called (${node.call_count} times)` : 'Called Function';
                }
                context.fillText(subtitle, canvas.width / 2, 55);

                context.font = '14px Arial';
                context.fillStyle = 'rgba(255, 255, 255, 0.7)';
                const locationText = `${node.filename || ''}:${node.line || 1}:${node.column || 1}`;
                context.fillText(locationText, canvas.width / 2, 78);

                context.font = '12px Arial';
                context.fillStyle = 'rgba(255, 255, 255, 0.6)';
                context.fillText('Click to open in Neovim', canvas.width / 2, 98);

                const texture = new THREE.CanvasTexture(canvas);
                const material = new THREE.SpriteMaterial({ 
                    map: texture,
                    transparent: true,
                    opacity: 0.95
                });
                const sprite = new THREE.Sprite(material);
                sprite.scale.set(16, 4.5, 1);
                sprite.userData = { index: index };
                scene.add(sprite);
                labels.push(sprite);
            }

            function initialLayout() {
                if (nodes.length === 0) return;

                let rootIndex = nodes.findIndex(n => n.type === 'root' || n.isDefinition);
                let incomingNodes = [];
                let outgoingNodes = [];

                nodes.forEach((node, index) => {
                    if (node.type === 'incoming' || node.isIncoming) {
                        incomingNodes.push(index);
                    } else if (node.type === 'outgoing' || node.isOutgoing) {
                        outgoingNodes.push(index);
                    }
                });

                if (rootIndex !== -1) {
                    nodePhysics[rootIndex].x = 0;
                    nodePhysics[rootIndex].y = 0;
                    nodePhysics[rootIndex].z = 0;
                }

                if (incomingNodes.length > 0) {
                    const radius = 20;
                    const angleStep = (Math.PI * 1.5) / Math.max(incomingNodes.length, 1);
                    incomingNodes.forEach((index, i) => {
                        const angle = -Math.PI * 0.75 + angleStep * i;
                        nodePhysics[index].x = Math.cos(angle) * radius - 15;
                        nodePhysics[index].y = Math.sin(angle) * radius;
                        nodePhysics[index].z = (Math.random() - 0.5) * 10;
                    });
                }

                if (outgoingNodes.length > 0) {
                    const radius = 20;
                    const angleStep = (Math.PI * 1.5) / Math.max(outgoingNodes.length, 1);
                    outgoingNodes.forEach((index, i) => {
                        const angle = Math.PI * 0.25 + angleStep * i;
                        nodePhysics[index].x = Math.cos(angle) * radius + 15;
                        nodePhysics[index].y = Math.sin(angle) * radius;
                        nodePhysics[index].z = (Math.random() - 0.5) * 10;
                    });
                }

                updateNodePositions();
            }

            function updateForces() {
                if (!physicsEnabled) return;

                const nodeCount = nodePhysics.length;
                const dynamicDamping = nodeCount < 5 ? 0.75 : DAMPING;
                const dynamicCenterForce = nodeCount < 5 ? CENTER_FORCE * 2 : CENTER_FORCE;

                nodePhysics.forEach(physics => {
                    physics.fx = physics.fy = physics.fz = 0;
                });

                for (let i = 0; i < nodePhysics.length; i++) {
                    for (let j = i + 1; j < nodePhysics.length; j++) {
                        const dx = nodePhysics[i].x - nodePhysics[j].x;
                        const dy = nodePhysics[i].y - nodePhysics[j].y;
                        const dz = nodePhysics[i].z - nodePhysics[j].z;
                        const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

                        if (distance > 0) {
                            const force = REPULSION_FORCE * forceStrength / (distance * distance);
                            const fx = (dx / distance) * force;
                            const fy = (dy / distance) * force;
                            const fz = (dz / distance) * force;

                            nodePhysics[i].fx += fx;
                            nodePhysics[i].fy += fy;
                            nodePhysics[i].fz += fz;
                            nodePhysics[j].fx -= fx;
                            nodePhysics[j].fy -= fy;
                            nodePhysics[j].fz -= fz;
                        }
                    }
                }

                edges.forEach(edge => {
                    const sourceIndex = nodes.findIndex(n => n.id === edge.source);
                    const targetIndex = nodes.findIndex(n => n.id === edge.target);

                    if (sourceIndex !== -1 && targetIndex !== -1) {
                        const dx = nodePhysics[targetIndex].x - nodePhysics[sourceIndex].x;
                        const dy = nodePhysics[targetIndex].y - nodePhysics[sourceIndex].y;
                        const dz = nodePhysics[targetIndex].z - nodePhysics[sourceIndex].z;
                        const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

                        const idealDistance = 10;
                        const force = SPRING_FORCE * forceStrength * (distance - idealDistance);

                        if (distance > 0) {
                            const fx = (dx / distance) * force;
                            const fy = (dy / distance) * force;
                            const fz = (dz / distance) * force;

                            nodePhysics[sourceIndex].fx += fx;
                            nodePhysics[sourceIndex].fy += fy;
                            nodePhysics[sourceIndex].fz += fz;
                            nodePhysics[targetIndex].fx -= fx;
                            nodePhysics[targetIndex].fy -= fy;
                            nodePhysics[targetIndex].fz -= fz;
                        }
                    }
                });

                nodePhysics.forEach(physics => {
                    physics.fx -= physics.x * dynamicCenterForce * forceStrength;
                    physics.fy -= physics.y * dynamicCenterForce * forceStrength;
                    physics.fz -= physics.z * dynamicCenterForce * forceStrength;
                });

                nodePhysics.forEach(physics => {
                    physics.vx = (physics.vx + physics.fx) * dynamicDamping;
                    physics.vy = (physics.vy + physics.fy) * dynamicDamping;
                    physics.vz = (physics.vz + physics.fz) * dynamicDamping;

                    physics.x += physics.vx;
                    physics.y += physics.vy;
                    physics.z += physics.vz;
                });

                const totalKineticEnergy = nodePhysics.reduce((sum, physics) => {
                    return sum + physics.vx * physics.vx + physics.vy * physics.vy + physics.vz * physics.vz;
                }, 0);

                if (totalKineticEnergy < 0.01 && physicsEnabled) {
                    setTimeout(() => {
                        if (totalKineticEnergy < 0.01) {
                            physicsEnabled = false;
                            document.getElementById('togglePhysics').textContent = 'Resume Physics';
                        }
                    }, 1000);
                }

                updateNodePositions();
            }

            function updateNodePositions() {
                nodeMeshes.forEach((mesh, index) => {
                    mesh.position.set(
                        nodePhysics[index].x,
                        nodePhysics[index].y,
                        nodePhysics[index].z
                    );
                });

                labels.forEach((label, index) => {
                    if (nodePhysics[label.userData.index]) {
                        label.position.set(
                            nodePhysics[label.userData.index].x,
                            nodePhysics[label.userData.index].y + 4,
                            nodePhysics[label.userData.index].z
                        );
                    }
                });

                edgeLines.forEach(element => {
                    if (element.userData.isArrow) {
                        const sourceIndex = element.userData.sourceIndex;
                        const targetIndex = element.userData.targetIndex;

                        const sourcePos = new THREE.Vector3(
                            nodePhysics[sourceIndex].x,
                            nodePhysics[sourceIndex].y,
                            nodePhysics[sourceIndex].z
                        );
                        const targetPos = new THREE.Vector3(
                            nodePhysics[targetIndex].x,
                            nodePhysics[targetIndex].y,
                            nodePhysics[targetIndex].z
                        );

                        const midPoint = sourcePos.clone().lerp(targetPos, 0.7);
                        element.position.copy(midPoint);

                        const direction = targetPos.clone().sub(sourcePos).normalize();
                        element.lookAt(midPoint.clone().add(direction));
                        element.rotateX(Math.PI / 2);

                    } else {
                        const positions = element.geometry.attributes.position.array;
                        const sourceIndex = element.userData.sourceIndex;
                        const targetIndex = element.userData.targetIndex;

                        positions[0] = nodePhysics[sourceIndex].x;
                        positions[1] = nodePhysics[sourceIndex].y;
                        positions[2] = nodePhysics[sourceIndex].z;
                        positions[3] = nodePhysics[targetIndex].x;
                        positions[4] = nodePhysics[targetIndex].y;
                        positions[5] = nodePhysics[targetIndex].z;

                        element.geometry.attributes.position.needsUpdate = true;
                    }
                });
            }

            function updateLabelsVisibility() {
                labels.forEach(label => {
                    label.visible = showLabels;
                });
            }

            function togglePhysics() {
                physicsEnabled = !physicsEnabled;
                document.getElementById('togglePhysics').textContent = 
                    physicsEnabled ? 'Pause Physics' : 'Resume Physics';

                if (physicsEnabled) {
                    nodePhysics.forEach(physics => {
                        physics.vx += (Math.random() - 0.5) * 0.1;
                        physics.vy += (Math.random() - 0.5) * 0.1;
                        physics.vz += (Math.random() - 0.5) * 0.1;
                    });
                }
            }

            function onWindowResize() {
                camera.aspect = window.innerWidth / window.innerHeight;
                camera.updateProjectionMatrix();
                renderer.setSize(window.innerWidth, window.innerHeight);
            }

            function onMouseMove(event) {
                mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
                mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
            }

            function onMouseClick(event) {
                if (event.which === 1) {
                    raycaster.setFromCamera(mouse, camera);
                    const intersects = raycaster.intersectObjects(nodeMeshes);

                    if (intersects.length > 0) {
                        const clickedNode = intersects[0].object.userData.node;
                        const clickedIndex = intersects[0].object.userData.index;

                        visitedNodes.add(clickedNode.id);

                        openFile(clickedNode);

                        if (selectedNode === clickedNode) {
                            selectedNode = null;
                            resetNodeColors();
                            const summaryElement = document.getElementById('summary');
                            if (summaryElement) {
                                document.getElementById('info').innerHTML = 
                                    'LSP Call Chain Visualization<br><span id="summary">' + 
                                    summaryElement.textContent + '</span>';
                            }
                        } else {
                            selectedNode = clickedNode;
                            highlightNode(clickedIndex);

                            let nodeTypeText = '';
                            if (clickedNode.type === 'root') {
                                nodeTypeText = 'Current Function';
                            } else if (clickedNode.type === 'incoming') {
                                nodeTypeText = 'Caller';
                                if (clickedNode.call_count) {
                                    nodeTypeText += ` (${clickedNode.call_count} calls)`;
                                }
                            } else if (clickedNode.type === 'outgoing') {
                                nodeTypeText = 'Called Function';
                                if (clickedNode.call_count) {
                                    nodeTypeText += ` (${clickedNode.call_count} times)`;
                                }
                            }

                            const info = `${nodeTypeText}: ${clickedNode.name}<br>` +
                                        `File: ${clickedNode.filename}:${clickedNode.line}:${clickedNode.column}<br>` +
                                        `Opening in Neovim...`;
                            document.getElementById('info').innerHTML = info;
                        }
                    }
                }
            }

            function highlightNode(index) {
                resetNodeColors();
                nodeMeshes[index].material.emissive.setHex(0xffd700);
                nodeMeshes[index].scale.set(1.3, 1.3, 1.3);

                edges.forEach(edge => {
                    const sourceIndex = nodes.findIndex(n => n.id === edge.source);
                    const targetIndex = nodes.findIndex(n => n.id === edge.target);

                    if (sourceIndex === index || targetIndex === index) {
                        const relatedIndex = sourceIndex === index ? targetIndex : sourceIndex;
                        nodeMeshes[relatedIndex].material.emissive.setHex(0x666666);

                        edgeLines.forEach(element => {
                            if (element.userData.sourceIndex === sourceIndex && 
                                element.userData.targetIndex === targetIndex) {
                                element.material.color.setHex(0xffd700);
                                element.material.opacity = 1.0;
                            }
                        });
                    }
                });
            }

            function resetNodeColors() {
                nodeMeshes.forEach((mesh, index) => {
                    const node = nodes[index];
                    let defaultEmissive;

                    if (visitedNodes.has(node.id) && selectedNode !== node) {
                        defaultEmissive = 0x886600;
                    } else if (node.type === 'root') {
                        defaultEmissive = 0x443300;
                    } else if (node.type === 'incoming') {
                        defaultEmissive = 0x113344;
                    } else if (node.type === 'outgoing') {
                        defaultEmissive = 0x224422;
                    } else {
                        defaultEmissive = 0x113344;
                    }

                    mesh.material.emissive.setHex(defaultEmissive);
                    mesh.scale.set(1, 1, 1);
                });

                edgeLines.forEach(element => {
                    element.material.color.setHex(0x95a5a6);
                    element.material.opacity = element.userData.isArrow ? 0.8 : 0.6;
                });
            }

            function resetCamera() {
                cameraAngleX = 0;
                cameraAngleY = 0;
                camera.position.set(0, 0, 35);
                camera.lookAt(0, 0, 0);
            }

            function animate() {
                requestAnimationFrame(animate);
                updateForces();
                updateFlowingParticles();

                const time = Date.now() * 0.0005;
                nodeMeshes.forEach((mesh, i) => {
                    if (selectedNode !== mesh.userData.node) {
                        const scale = 1 + 0.03 * Math.sin(time + i);
                        mesh.scale.set(scale, scale, scale);
                    }
                });
                renderer.render(scene, camera);
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', loadThreeJS);
            } else {
                loadThreeJS();
            }
        </script>
    </body>
    </html>
    ]]

  return html
end

function M.send_data(data)
  data_to_visualize = data
end

function M.open()
  if url then
    vim.ui.open(url)
  end
end

return M
