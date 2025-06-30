local M = {}

function M.symbol_html(data_to_visualize)
  local json_data = data_to_visualize and vim.json.encode(data_to_visualize) or '{}'

  local html = [[
    <!DOCTYPE html>
    <html>
    <head>
        <title>LSP Code Galaxy Visualizer</title>
        <style>
            body { 
                margin: 0; 
                background: radial-gradient(ellipse at center, #0a0a2e 0%, #16213e 35%, #0f0f23 100%);
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                overflow: hidden;
                color: white;
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
                max-width: 250px;
            }
            #controls button {
                background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
                border: none;
                color: white;
                padding: 8px 12px;
                margin: 3px;
                border-radius: 6px;
                cursor: pointer;
                transition: all 0.3s ease;
                font-weight: 500;
                font-size: 12px;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            }
            #controls button:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
            }
            #controls label {
                margin: 5px 0;
                cursor: pointer;
                font-size: 12px;
                color: #b0b0b0;
                display: block;
            }
            #controls input[type="range"] {
                width: 100px;
                margin-left: 8px;
            }
            #controls input[type="text"] {
                width: 120px;
                padding: 4px;
                margin-left: 8px;
                border: 1px solid #444;
                background: rgba(255,255,255,0.1);
                color: white;
                border-radius: 4px;
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
                font-size: 11px;
                backdrop-filter: blur(15px);
                border: 1px solid rgba(255, 255, 255, 0.1);
                z-index: 1000;
                max-width: 200px;
                max-height: 60vh;
                overflow-y: auto;
            }
            .legend-item {
                display: flex;
                align-items: center;
                margin: 3px 0;
            }
            .legend-color {
                width: 12px;
                height: 12px;
                border-radius: 50%;
                margin-right: 6px;
                flex-shrink: 0;
            }
            #flight-hud {
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                pointer-events: none;
                z-index: 999;
            }
            .crosshair {
                width: 40px;
                height: 40px;
                border: 2px solid rgba(255, 255, 255, 0.8);
                border-radius: 50%;
                position: relative;
            }
            .crosshair::before,
            .crosshair::after {
                content: '';
                position: absolute;
                background: rgba(255, 255, 255, 0.8);
            }
            .crosshair::before {
                width: 2px;
                height: 20px;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
            }
            .crosshair::after {
                width: 20px;
                height: 2px;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
            }
            #speed-indicator {
                position: absolute;
                bottom: 100px;
                right: 20px;
                background: rgba(15, 15, 35, 0.9);
                padding: 10px;
                border-radius: 8px;
                font-family: 'Courier New', monospace;
                font-size: 12px;
                z-index: 1000;
            }
            .star-trail {
                position: absolute;
                width: 2px;
                height: 2px;
                background: white;
                border-radius: 50%;
                opacity: 0.6;
                pointer-events: none;
            }
        </style>
    </head>
    <body>
        <div id="info">Code Galaxy Explorer<br><span id="summary"></span></div>
        
        <div id="flight-hud">
            <div class="crosshair"></div>
        </div>
        
        <div id="speed-indicator">
            <div>Speed: <span id="current-speed">1.0</span></div>
            <div>Altitude: <span id="current-altitude">100</span></div>
            <div>Targets: <span id="target-count">0</span></div>
        </div>
        
        <div id="legend">
            <div><strong>Symbol Types</strong></div>
            <div class="legend-item">
                <div class="legend-color" style="background: #e74c3c;"></div>
                <span>Module/Package</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #f39c12;"></div>
                <span>Class/Struct</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #2980b9;"></div>
                <span>Function/Method</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #27ae60;"></div>
                <span>Variable/Field</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #8e44ad;"></div>
                <span>File/Other</span>
            </div>
            <div style="margin-top: 10px; padding-top: 8px; border-top: 1px solid rgba(255,255,255,0.2);">
                <div><strong>Navigation</strong></div>
                <div style="font-size: 10px; margin: 2px 0;">WASD/Arrow Keys: Move</div>
                <div style="font-size: 10px; margin: 2px 0;">Shift: Speed boost</div>
                <div style="font-size: 10px; margin: 2px 0;">Ctrl: Slow down</div>
                <div style="font-size: 10px; margin: 2px 0;">Click: Select star</div>
                <div style="font-size: 10px; margin: 2px 0;">Double-click: Open file</div>
            </div>
        </div>
        
        <div id="controls">
            <div><strong>Galaxy Controls</strong></div>
            <button id="resetView">Reset Position</button>
            <button id="toggleWarpMode">Warp Mode</button>
            <button id="findNearby">Find Nearby</button>
            <br>
            <label>
                <input type="checkbox" id="showLabels" checked> Labels
            </label>
            <label>
                <input type="checkbox" id="showTrails" checked> Trails
            </label>
            <label>
                <input type="checkbox" id="showSystems"> Systems
            </label>
            <br>
            <label>Search: <input type="text" id="searchInput" placeholder="Symbol name..."></label>
            <br>
            <label>View Distance: <input type="range" id="viewDistance" min="100" max="2000" value="800"></label>
            <label>Flight Speed: <input type="range" id="flightSpeed" min="0.1" max="5" step="0.1" value="1"></label>
        </div>

        <script>
            // 错误处理和Three.js加载
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
            let stars = [], starSystems = [];
            let starMeshes = [], systemMeshes = [], labels = [];
            let starField, nebula;
            let raycaster, mouse;
            let selectedStar = null;
            let showLabels = true;
            let showTrails = true;
            let showSystems = false;
            let isGalaxyMode = false;
            let warpMode = false;
            let flightSpeed = 1.0;
            let viewDistance = 800;

            // 飞行控制
            let keys = {};
            let velocity, direction; // 将在 init() 中初始化
            let moveSpeed = 2.0;
            let currentSpeed = 0;

            function init() {
                if (typeof THREE === 'undefined') {
                    console.error('THREE.js is not loaded');
                    return;
                }

                try {
                    scene = new THREE.Scene();
                    scene.background = new THREE.Color(0x000000);

                    camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 5000);
                    camera.position.set(0, 0, 100);

                    renderer = new THREE.WebGLRenderer({ antialias: true });
                    renderer.setSize(window.innerWidth, window.innerHeight);
                    renderer.setClearColor(0x000000);
                    document.body.appendChild(renderer.domElement);

                    raycaster = new THREE.Raycaster();
                    mouse = new THREE.Vector2();

                    // 初始化飞行控制向量
                    velocity = new THREE.Vector3();
                    direction = new THREE.Vector3();

                    setupLighting();
                    setupEventListeners();
                    loadGalaxyData();

                    createStarField();
                    if (isGalaxyMode) {
                        createNebula();
                    }

                    animate();
                } catch (error) {
                    console.error('Error initializing Three.js scene:', error);
                    document.getElementById('summary').textContent = 'Error loading 3D visualization';
                }
            }

            function setupLighting() {
                const ambientLight = new THREE.AmbientLight(0x404040, 0.6);
                scene.add(ambientLight);

                // 创建多个点光源模拟星光
                const colors = [0xffffff, 0xffffaa, 0xaaaaff, 0xffaaaa];
                for (let i = 0; i < 4; i++) {
                    const light = new THREE.PointLight(colors[i], 0.8, 1000);
                    light.position.set(
                        (Math.random() - 0.5) * 500,
                        (Math.random() - 0.5) * 500,
                        (Math.random() - 0.5) * 500
                    );
                    scene.add(light);
                }
            }

            function setupEventListeners() {
                window.addEventListener('resize', onWindowResize, false);
                window.addEventListener('mousemove', onMouseMove, false);
                window.addEventListener('click', onMouseClick, false);
                window.addEventListener('dblclick', onDoubleClick, false);
                window.addEventListener('keydown', onKeyDown, false);
                window.addEventListener('keyup', onKeyUp, false);

                document.getElementById('resetView').addEventListener('click', resetCamera);
                document.getElementById('toggleWarpMode').addEventListener('click', toggleWarpMode);
                document.getElementById('findNearby').addEventListener('click', findNearbyStars);
                
                document.getElementById('showLabels').addEventListener('change', function(e) {
                    showLabels = e.target.checked;
                    updateLabelsVisibility();
                });
                
                document.getElementById('showTrails').addEventListener('change', function(e) {
                    showTrails = e.target.checked;
                });
                
                document.getElementById('showSystems').addEventListener('change', function(e) {
                    showSystems = e.target.checked;
                    updateSystemsVisibility();
                });

                document.getElementById('viewDistance').addEventListener('input', function(e) {
                    viewDistance = parseFloat(e.target.value);
                    camera.far = viewDistance;
                    camera.updateProjectionMatrix();
                });

                document.getElementById('flightSpeed').addEventListener('input', function(e) {
                    flightSpeed = parseFloat(e.target.value);
                });

                document.getElementById('searchInput').addEventListener('input', function(e) {
                    searchStars(e.target.value);
                });
            }

            function loadGalaxyData() {
                const data = LSP_DATA;

                if (!data || (!data.nodes && !data.star_systems)) {
                    document.getElementById('summary').textContent = 'No galaxy data to visualize';
                    return;
                }

                // 检查是否是星系模式
                isGalaxyMode = data.type === 'galaxy' && data.star_systems;

                if (isGalaxyMode) {
                    loadGalaxy(data);
                } else {
                    loadCallHierarchy(data);
                }
            }

            function loadGalaxy(data) {
                stars = data.nodes || [];
                starSystems = data.star_systems || [];

                let summaryText = `✨ ${data.summary.galaxy_name || 'Code Galaxy'} ✨`;
                if (data.summary.total_stars) {
                    summaryText += ` | ${data.summary.total_stars} Stars in ${data.summary.total_systems} Systems`;
                }
                if (data.summary.largest_system) {
                    summaryText += ` | Largest: ${data.summary.largest_system}`;
                }
                document.getElementById('summary').textContent = summaryText;
                document.getElementById('target-count').textContent = stars.length;

                clearScene();
                createGalaxy();
            }

            function loadCallHierarchy(data) {
                // 原有的调用层次逻辑
                isGalaxyMode = false;
                stars = data.nodes || [];
                
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
                        `Nodes: ${stars.length} | Edges: ${data.edges ? data.edges.length : 0}`;
                }

                clearScene();
                createCallHierarchy(data);
            }

            function createGalaxy() {
                // 计算星系系统的位置
                const systemCount = starSystems.length;
                const galaxyRadius = Math.max(systemCount * 30, 200);
                
                // 为每个星系系统分配位置（螺旋星系结构）
                starSystems.forEach((system, index) => {
                    const angle = (index / systemCount) * Math.PI * 4; // 螺旋角度
                    const radius = (index / systemCount) * galaxyRadius;
                    const height = (Math.random() - 0.5) * galaxyRadius * 0.1;
                    
                    system.center = {
                        x: Math.cos(angle) * radius,
                        y: height,
                        z: Math.sin(angle) * radius
                    };
                });

                // 创建星系系统的视觉表示
                if (showSystems) {
                    createSystemVisuals();
                }

                // 在每个系统内部创建星球
                stars.forEach((star, index) => {
                    createStar(star, index);
                });

                updateLabelsVisibility();
            }

            function createSystemVisuals() {
                starSystems.forEach(system => {
                    // 创建星系系统的环形结构
                    const ringGeometry = new THREE.RingGeometry(system.radius * 0.8, system.radius, 32);
                    const ringMaterial = new THREE.MeshBasicMaterial({
                        color: 0x444444,
                        transparent: true,
                        opacity: 0.1,
                        side: THREE.DoubleSide
                    });
                    const ring = new THREE.Mesh(ringGeometry, ringMaterial);
                    ring.position.set(system.center.x, system.center.y, system.center.z);
                    ring.rotation.x = Math.PI / 2;
                    scene.add(ring);
                    systemMeshes.push(ring);

                    // 系统名称标签
                    addSystemLabel(system);
                });
            }

            function createStar(star, index) {
                // 计算星球在其所属系统中的位置
                let position = { x: 0, y: 0, z: 0 };
                
                if (isGalaxyMode && star.system_id) {
                    const system = starSystems.find(s => s.id === star.system_id);
                    if (system) {
                        // 在系统内随机分布
                        const angle = (star.local_index / system.symbol_count) * Math.PI * 2;
                        const distance = Math.random() * system.radius * 0.6;
                        const height = (Math.random() - 0.5) * system.radius * 0.1;
                        
                        position = {
                            x: system.center.x + Math.cos(angle) * distance,
                            y: system.center.y + height,
                            z: system.center.z + Math.sin(angle) * distance
                        };
                    }
                } else {
                    // 原有的布局逻辑用于调用层次
                    position = {
                        x: (Math.random() - 0.5) * 100,
                        y: (Math.random() - 0.5) * 100,
                        z: (Math.random() - 0.5) * 100
                    };
                }

                // 根据符号类型和重要性创建几何体
                const size = Math.max(star.size || 1, 0.5);
                const color = star.color || 0x4ecdc4;
                
                let geometry;
                if (star.symbolType === 'class' || star.symbolType === 'struct') {
                    geometry = new THREE.OctahedronGeometry(size, 1);
                } else if (star.symbolType === 'function' || star.symbolType === 'method') {
                    geometry = new THREE.TetrahedronGeometry(size, 0);
                } else if (star.symbolType === 'module' || star.symbolType === 'package') {
                    geometry = new THREE.DodecahedronGeometry(size, 0);
                } else {
                    geometry = new THREE.SphereGeometry(size, 12, 8);
                }

                const material = new THREE.MeshPhongMaterial({
                    color: color,
                    emissive: color,
                    emissiveIntensity: 0.3,
                    shininess: 100,
                    transparent: true,
                    opacity: 0.9
                });

                const mesh = new THREE.Mesh(geometry, material);
                mesh.position.set(position.x, position.y, position.z);
                mesh.userData = { star: star, index: index };

                // 添加发光效果
                const glowGeometry = new THREE.SphereGeometry(size * 1.5, 12, 8);
                const glowMaterial = new THREE.MeshBasicMaterial({
                    color: color,
                    transparent: true,
                    opacity: 0.2
                });
                const glow = new THREE.Mesh(glowGeometry, glowMaterial);
                glow.position.copy(mesh.position);
                scene.add(glow);

                scene.add(mesh);
                starMeshes.push(mesh);

                // 添加粒子尾迹
                if (showTrails && isGalaxyMode) {
                    createStarTrail(mesh, color);
                }

                addStarLabel(mesh, star, index);
            }

            function createStarTrail(starMesh, color) {
                const particleCount = 20;
                const particles = new THREE.BufferGeometry();
                const positions = new Float32Array(particleCount * 3);
                const colors = new Float32Array(particleCount * 3);
                
                const c = new THREE.Color(color);
                for (let i = 0; i < particleCount; i++) {
                    positions[i * 3] = starMesh.position.x;
                    positions[i * 3 + 1] = starMesh.position.y;
                    positions[i * 3 + 2] = starMesh.position.z;
                    
                    colors[i * 3] = c.r;
                    colors[i * 3 + 1] = c.g;
                    colors[i * 3 + 2] = c.b;
                }
                
                particles.setAttribute('position', new THREE.BufferAttribute(positions, 3));
                particles.setAttribute('color', new THREE.BufferAttribute(colors, 3));
                
                const particleMaterial = new THREE.PointsMaterial({
                    size: 0.5,
                    vertexColors: true,
                    transparent: true,
                    opacity: 0.6,
                    blending: THREE.AdditiveBlending
                });
                
                const trail = new THREE.Points(particles, particleMaterial);
                scene.add(trail);
                starMeshes.push(trail);
            }

            function createCallHierarchy(data) {
                // 原有的调用层次创建逻辑
                stars.forEach((star, index) => {
                    createStar(star, index);
                });
                
                // 创建边（如果存在）
                if (data.edges) {
                    createEdges(data.edges);
                }
            }

            function createEdges(edges) {
                edges.forEach(edge => {
                    const sourceIndex = stars.findIndex(n => n.id === edge.source);
                    const targetIndex = stars.findIndex(n => n.id === edge.target);

                    if (sourceIndex !== -1 && targetIndex !== -1) {
                        const material = new THREE.LineBasicMaterial({
                            color: 0x95a5a6,
                            transparent: true,
                            opacity: 0.6
                        });

                        const geometry = new THREE.BufferGeometry();
                        const positions = new Float32Array(6);
                        
                        const sourceMesh = starMeshes[sourceIndex];
                        const targetMesh = starMeshes[targetIndex];
                        
                        positions[0] = sourceMesh.position.x;
                        positions[1] = sourceMesh.position.y;
                        positions[2] = sourceMesh.position.z;
                        positions[3] = targetMesh.position.x;
                        positions[4] = targetMesh.position.y;
                        positions[5] = targetMesh.position.z;
                        
                        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

                        const line = new THREE.Line(geometry, material);
                        scene.add(line);
                        starMeshes.push(line);
                    }
                });
            }

            function createStarField() {
                const starfieldGeometry = new THREE.BufferGeometry();
                const starfieldCount = 10000;
                const positions = new Float32Array(starfieldCount * 3);
                
                for (let i = 0; i < starfieldCount; i++) {
                    positions[i * 3] = (Math.random() - 0.5) * 4000;
                    positions[i * 3 + 1] = (Math.random() - 0.5) * 4000;
                    positions[i * 3 + 2] = (Math.random() - 0.5) * 4000;
                }
                
                starfieldGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
                
                const starfieldMaterial = new THREE.PointsMaterial({
                    color: 0xffffff,
                    size: 0.5,
                    transparent: true,
                    opacity: 0.8
                });
                
                starField = new THREE.Points(starfieldGeometry, starfieldMaterial);
                scene.add(starField);
            }

            function createNebula() {
                // 创建星云效果
                const nebulaGeometry = new THREE.SphereGeometry(800, 32, 32);
                const nebulaMaterial = new THREE.MeshBasicMaterial({
                    color: 0x663399,
                    transparent: true,
                    opacity: 0.05,
                    side: THREE.BackSide
                });
                nebula = new THREE.Mesh(nebulaGeometry, nebulaMaterial);
                scene.add(nebula);
            }

            function addStarLabel(mesh, star, index) {
                const canvas = document.createElement('canvas');
                const context = canvas.getContext('2d');
                canvas.width = 300;
                canvas.height = 80;

                const gradient = context.createLinearGradient(0, 0, canvas.width, canvas.height);
                const color = new THREE.Color(star.color || 0x4ecdc4);
                gradient.addColorStop(0, `rgba(${Math.floor(color.r*255)}, ${Math.floor(color.g*255)}, ${Math.floor(color.b*255)}, 0.9)`);
                gradient.addColorStop(1, `rgba(${Math.floor(color.r*255*0.6)}, ${Math.floor(color.g*255*0.6)}, ${Math.floor(color.b*255*0.6)}, 0.9)`);
                
                context.fillStyle = gradient;
                context.fillRect(0, 0, canvas.width, canvas.height);
                
                context.strokeStyle = 'rgba(255, 255, 255, 0.4)';
                context.lineWidth = 1;
                context.strokeRect(0, 0, canvas.width, canvas.height);
                
                context.fillStyle = 'white';
                context.textAlign = 'center';
                context.shadowColor = 'rgba(0, 0, 0, 0.8)';
                context.shadowBlur = 2;
                
                context.font = 'bold 16px Arial';
                context.fillText(star.name, canvas.width / 2, 25);
                
                context.font = '12px Arial';
                context.fillStyle = 'rgba(255, 255, 255, 0.9)';
                const subtitle = star.symbolName || star.type || 'Symbol';
                context.fillText(subtitle, canvas.width / 2, 42);

                context.font = '10px Arial';
                context.fillStyle = 'rgba(255, 255, 255, 0.7)';
                const locationText = `${star.filename}:${star.line}:${star.column}`;
                context.fillText(locationText, canvas.width / 2, 58);

                const texture = new THREE.CanvasTexture(canvas);
                const material = new THREE.SpriteMaterial({ 
                    map: texture,
                    transparent: true,
                    opacity: 0.9
                });
                const sprite = new THREE.Sprite(material);
                sprite.scale.set(12, 3.2, 1);
                sprite.position.copy(mesh.position);
                sprite.position.y += star.size * 2 + 2;
                sprite.userData = { index: index };
                scene.add(sprite);
                labels.push(sprite);
            }

            function addSystemLabel(system) {
                const canvas = document.createElement('canvas');
                const context = canvas.getContext('2d');
                canvas.width = 200;
                canvas.height = 40;

                context.fillStyle = 'rgba(255, 255, 255, 0.8)';
                context.fillRect(0, 0, canvas.width, canvas.height);
                
                context.fillStyle = 'black';
                context.textAlign = 'center';
                context.font = 'bold 14px Arial';
                context.fillText(system.name, canvas.width / 2, 25);

                const texture = new THREE.CanvasTexture(canvas);
                const material = new THREE.SpriteMaterial({ 
                    map: texture,
                    transparent: true,
                    opacity: 0.8
                });
                const sprite = new THREE.Sprite(material);
                sprite.scale.set(20, 4, 1);
                sprite.position.set(system.center.x, system.center.y + system.radius + 10, system.center.z);
                scene.add(sprite);
                labels.push(sprite);
            }

            function clearScene() {
                starMeshes.forEach(mesh => scene.remove(mesh));
                systemMeshes.forEach(mesh => scene.remove(mesh));
                labels.forEach(label => scene.remove(label));
                
                starMeshes = [];
                systemMeshes = [];
                labels = [];
            }

            function updateLabelsVisibility() {
                labels.forEach(label => {
                    label.visible = showLabels;
                });
            }

            function updateSystemsVisibility() {
                systemMeshes.forEach(mesh => {
                    mesh.visible = showSystems;
                });
            }

            // 飞行控制
            function onKeyDown(event) {
                keys[event.code] = true;
            }

            function onKeyUp(event) {
                keys[event.code] = false;
            }

            function updateFlightControls() {
                if (!isGalaxyMode || !direction || !velocity) return;

                const speed = warpMode ? moveSpeed * 10 : moveSpeed;
                let currentSpeedMultiplier = flightSpeed;
                
                if (keys['ShiftLeft'] || keys['ShiftRight']) {
                    currentSpeedMultiplier *= 3; // 加速
                }
                if (keys['ControlLeft'] || keys['ControlRight']) {
                    currentSpeedMultiplier *= 0.3; // 减速
                }

                direction.set(0, 0, 0);

                if (keys['KeyW'] || keys['ArrowUp']) direction.z -= 1;
                if (keys['KeyS'] || keys['ArrowDown']) direction.z += 1;
                if (keys['KeyA'] || keys['ArrowLeft']) direction.x -= 1;
                if (keys['KeyD'] || keys['ArrowRight']) direction.x += 1;
                if (keys['KeyQ']) direction.y += 1;
                if (keys['KeyE']) direction.y -= 1;

                if (direction.length() > 0) {
                    direction.normalize();
                    direction.multiplyScalar(speed * currentSpeedMultiplier);
                    
                    camera.position.add(direction);
                    currentSpeed = direction.length();
                } else {
                    currentSpeed *= 0.95; // 阻力
                }

                // 更新HUD
                document.getElementById('current-speed').textContent = currentSpeed.toFixed(1);
                document.getElementById('current-altitude').textContent = Math.abs(camera.position.y).toFixed(0);
            }

            function toggleWarpMode() {
                warpMode = !warpMode;
                document.getElementById('toggleWarpMode').textContent = warpMode ? 'Normal Mode' : 'Warp Mode';
                
                if (warpMode) {
                    // 创建曲速效果
                    starField.material.size = 2;
                    starField.material.opacity = 1;
                } else {
                    starField.material.size = 0.5;
                    starField.material.opacity = 0.8;
                }
            }

            function findNearbyStars() {
                const nearbyStars = [];
                const searchRadius = 50;
                
                starMeshes.forEach((mesh, index) => {
                    if (mesh.userData && mesh.userData.star) {
                        const distance = camera.position.distanceTo(mesh.position);
                        if (distance < searchRadius) {
                            nearbyStars.push({
                                star: mesh.userData.star,
                                distance: distance,
                                mesh: mesh
                            });
                        }
                    }
                });

                nearbyStars.sort((a, b) => a.distance - b.distance);
                
                if (nearbyStars.length > 0) {
                    const nearest = nearbyStars[0];
                    selectStar(nearest.mesh);
                    
                    const info = `Nearest: ${nearest.star.name} (${nearest.distance.toFixed(1)} units)`;
                    document.getElementById('info').innerHTML = 
                        `Code Galaxy Explorer<br><span id="summary">${info}</span>`;
                } else {
                    document.getElementById('info').innerHTML = 
                        `Code Galaxy Explorer<br><span id="summary">No stars nearby</span>`;
                }
            }

            function searchStars(query) {
                if (!query.trim()) {
                    resetStarColors();
                    return;
                }

                resetStarColors();
                let found = 0;
                
                starMeshes.forEach(mesh => {
                    if (mesh.userData && mesh.userData.star) {
                        const star = mesh.userData.star;
                        if (star.name.toLowerCase().includes(query.toLowerCase()) ||
                            (star.filename && star.filename.toLowerCase().includes(query.toLowerCase()))) {
                            mesh.material.emissive.setHex(0xffd700);
                            mesh.scale.set(1.5, 1.5, 1.5);
                            found++;
                        }
                    }
                });

                document.getElementById('summary').textContent = 
                    `Found ${found} stars matching "${query}"`;
            }

            function resetStarColors() {
                starMeshes.forEach(mesh => {
                    if (mesh.userData && mesh.userData.star) {
                        const star = mesh.userData.star;
                        const color = star.color || 0x4ecdc4;
                        mesh.material.emissive.setHex(color);
                        mesh.material.emissiveIntensity = 0.3;
                        mesh.scale.set(1, 1, 1);
                    }
                });
            }

            function selectStar(mesh) {
                resetStarColors();
                selectedStar = mesh.userData.star;
                
                mesh.material.emissive.setHex(0xffffff);
                mesh.material.emissiveIntensity = 0.8;
                mesh.scale.set(1.8, 1.8, 1.8);

                const star = selectedStar;
                const info = `Selected: ${star.name} (${star.symbolName || star.type})<br>` +
                            `File: ${star.filename}:${star.line}:${star.column}`;
                document.getElementById('info').innerHTML = info;
            }

            function openFile(star) {
                if (!star.filepath) {
                    console.error('No filepath available for star:', star);
                    return;
                }

                const requestData = {
                    filepath: star.filepath,
                    line: star.line || 1,
                    column: star.column || 1
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
                        console.log('File opened successfully:', star.filepath);
                    } else {
                        console.error('Failed to open file:', data.error);
                    }
                })
                .catch(error => {
                    console.error('Error opening file:', error);
                });
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
                raycaster.setFromCamera(mouse, camera);
                const intersects = raycaster.intersectObjects(starMeshes);

                if (intersects.length > 0) {
                    const clickedMesh = intersects[0].object;
                    if (clickedMesh.userData && clickedMesh.userData.star) {
                        selectStar(clickedMesh);
                    }
                }
            }

            function onDoubleClick(event) {
                raycaster.setFromCamera(mouse, camera);
                const intersects = raycaster.intersectObjects(starMeshes);

                if (intersects.length > 0) {
                    const clickedMesh = intersects[0].object;
                    if (clickedMesh.userData && clickedMesh.userData.star) {
                        openFile(clickedMesh.userData.star);
                    }
                }
            }

            function resetCamera() {
                camera.position.set(0, 0, 100);
                camera.lookAt(0, 0, 0);
                currentSpeed = 0;
                if (velocity) {
                    velocity.set(0, 0, 0);
                }
            }

            function animate() {
                requestAnimationFrame(animate);
                
                updateFlightControls();
                
                // 星球自转动画
                const time = Date.now() * 0.0005;
                starMeshes.forEach((mesh, i) => {
                    if (mesh.userData && mesh.userData.star) {
                        mesh.rotation.y = time + i * 0.1;
                        mesh.rotation.x = time * 0.5 + i * 0.05;
                        
                        // 轻微的脉动效果
                        const scale = 1 + 0.05 * Math.sin(time * 2 + i);
                        if (selectedStar !== mesh.userData.star) {
                            mesh.scale.set(scale, scale, scale);
                        }
                    }
                });

                // 星云旋转
                if (nebula) {
                    nebula.rotation.y = time * 0.1;
                }

                // 曲速效果
                if (warpMode && starField) {
                    starField.rotation.z = time * 0.5;
                }

                renderer.render(scene, camera);
            }

            // 页面加载完成后开始
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

return M
