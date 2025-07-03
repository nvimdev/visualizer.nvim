local M = {}

function M.symbol_html(data_to_visualize)
  local json_data = data_to_visualize and vim.json.encode(data_to_visualize) or '{}'

  local html = [[
    <!DOCTYPE html>
    <html>
    <head>
        <title>Code Structure Explorer</title>
        <style>
            body {
                margin: 0;
                background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                overflow: hidden;
                color: white;
                user-select: none;
            }
            #info {
                position: absolute;
                top: 15px;
                width: 100%;
                text-align: center;
                color: #e0e0e0;
                font-family: 'Courier New', monospace;
                pointer-events: none;
                font-size: 16px;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
                line-height: 1.4;
                z-index: 1000;
            }
            #searchBox {
                position: absolute;
                top: 80px;
                width: 100%;
                text-align: center;
                z-index: 1000;
                pointer-events: none;
            }
            #searchContainer {
                display: inline-block;
                position: relative;
                pointer-events: auto;
            }
            #searchBox input {
                background: rgba(20, 20, 20, 0.95);
                border: 2px solid rgba(74, 144, 226, 0.8);
                color: white;
                padding: 12px 45px 12px 20px;
                border-radius: 25px;
                font-size: 14px;
                width: 300px;
                text-align: left;
                backdrop-filter: blur(10px);
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
                transition: all 0.3s ease;
            }
            #searchBox input:focus {
                outline: none;
                border-color: #4a90e2;
                box-shadow: 0 4px 25px rgba(74, 144, 226, 0.4);
                transform: scale(1.05);
            }
            #searchBox input::placeholder {
                color: #888;
            }
            #clearSearchBtn {
                position: absolute;
                right: 8px;
                top: 50%;
                transform: translateY(-50%);
                background: rgba(255, 255, 255, 0.1);
                border: none;
                color: #ccc;
                width: 30px;
                height: 30px;
                border-radius: 50%;
                cursor: pointer;
                display: none;
                align-items: center;
                justify-content: center;
                font-size: 14px;
                font-family: Arial, sans-serif;
                transition: all 0.2s ease;
            }
            #clearSearchBtn::before {
                content: 'X';
                font-weight: bold;
            }
            #clearSearchBtn:hover {
                background: rgba(255, 255, 255, 0.2);
                color: white;
                transform: translateY(-50%) scale(1.1);
            }
            #clearSearchBtn.show {
                display: flex;
            }
            #controls {
                position: absolute;
                bottom: 20px;
                left: 20px;
                background: rgba(20, 20, 20, 0.95);
                padding: 20px;
                border-radius: 8px;
                color: white;
                font-family: sans-serif;
                border: 1px solid rgba(255, 255, 255, 0.2);
                z-index: 1000;
                max-width: 320px;
                backdrop-filter: blur(10px);
            }
            #controls button {
                background: linear-gradient(45deg, #4a90e2 0%, #357abd 100%);
                border: none;
                color: white;
                padding: 8px 12px;
                margin: 4px;
                border-radius: 4px;
                cursor: pointer;
                transition: all 0.2s ease;
                font-size: 12px;
            }
            #controls button:hover {
                background: linear-gradient(45deg, #5ba0f2 0%, #4a8acd 100%);
                transform: translateY(-1px);
            }
            #controls button.active {
                background: linear-gradient(45deg, #27ae60 0%, #219a52 100%);
            }
            #controls label {
                margin: 6px 0;
                cursor: pointer;
                font-size: 12px;
                color: #ccc;
                display: block;
            }
            #controls input[type="range"] {
                width: 100px;
                margin-left: 8px;
            }
            #controls input[type="text"] {
                width: 140px;
                padding: 6px;
                margin-left: 8px;
                border: 1px solid #555;
                background: rgba(255,255,255,0.1);
                color: white;
                border-radius: 3px;
                font-size: 11px;
            }
            #controls input[type="text"]:focus {
                outline: none;
                border-color: #4a90e2;
                box-shadow: 0 0 5px rgba(74, 144, 226, 0.5);
            }
            #fileFilter {
                position: absolute;
                top: 80px;
                left: 20px;
                background: rgba(20, 20, 20, 0.95);
                padding: 15px;
                border-radius: 8px;
                color: white;
                font-family: sans-serif;
                font-size: 11px;
                border: 1px solid rgba(255, 255, 255, 0.2);
                z-index: 1000;
                max-width: 300px;
                max-height: 400px;
                overflow-y: auto;
                backdrop-filter: blur(10px);
            }
            #fileSearchBox {
                margin-bottom: 10px;
            }
            #fileSearchBox input {
                width: 100%;
                padding: 6px;
                border: 1px solid #555;
                background: rgba(255,255,255,0.1);
                color: white;
                border-radius: 3px;
                font-size: 11px;
                box-sizing: border-box;
            }
            #fileSearchBox input:focus {
                outline: none;
                border-color: #4a90e2;
            }
            .file-item {
                padding: 6px 8px;
                margin: 2px 0;
                border-radius: 3px;
                cursor: pointer;
                transition: background 0.2s;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            .file-item:hover {
                background: rgba(74, 144, 226, 0.3);
            }
            .file-item.active {
                background: rgba(39, 174, 96, 0.4);
            }
            .file-item.hidden {
                display: none;
            }
            .file-content {
                display: flex;
                align-items: center;
                flex: 1;
            }
            .file-checkbox {
                margin-right: 8px;
                transform: scale(0.9);
            }
            .file-count {
                color: #888;
                font-size: 10px;
                margin-left: 8px;
            }
            #legend {
                position: absolute;
                top: 20px;
                right: 20px;
                background: rgba(20, 20, 20, 0.95);
                padding: 15px;
                border-radius: 8px;
                color: white;
                font-family: sans-serif;
                font-size: 12px;
                border: 1px solid rgba(255, 255, 255, 0.2);
                z-index: 1000;
                max-width: 220px;
                backdrop-filter: blur(10px);
            }
            .legend-item {
                display: flex;
                align-items: center;
                margin: 4px 0;
            }
            .legend-color {
                width: 12px;
                height: 12px;
                border-radius: 2px;
                margin-right: 6px;
                flex-shrink: 0;
            }
            #stats {
                position: absolute;
                bottom: 20px;
                right: 20px;
                background: rgba(20, 20, 20, 0.95);
                padding: 12px;
                border-radius: 8px;
                font-family: 'Courier New', monospace;
                font-size: 11px;
                z-index: 1000;
                border: 1px solid rgba(255, 255, 255, 0.2);
                backdrop-filter: blur(10px);
            }
            #searchResults {
                position: absolute;
                top: 140px;
                left: 50%;
                transform: translateX(-50%);
                background: rgba(20, 20, 20, 0.95);
                padding: 12px;
                border-radius: 8px;
                color: white;
                font-family: sans-serif;
                font-size: 12px;
                border: 1px solid rgba(255, 255, 255, 0.2);
                z-index: 1000;
                max-width: 400px;
                max-height: 300px;
                overflow-y: auto;
                backdrop-filter: blur(10px);
                display: none;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
            }
            .search-item {
                padding: 6px 8px;
                margin: 2px 0;
                border-radius: 3px;
                cursor: pointer;
                transition: background 0.2s;
                border-left: 3px solid transparent;
            }
            .search-item:hover {
                background: rgba(74, 144, 226, 0.3);
                border-left-color: #4a90e2;
            }
            .search-item.selected {
                background: rgba(255, 215, 0, 0.2);
                border-left-color: #ffd700;
            }
            .search-item.first-result {
                border-left: 3px solid #4a90e2;
            }
            #crosshair {
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                width: 20px;
                height: 20px;
                border: 1px solid rgba(255, 255, 255, 0.3);
                pointer-events: none;
                z-index: 999;
            }
            #crosshair::before, #crosshair::after {
                content: '';
                position: absolute;
                background: rgba(255, 255, 255, 0.3);
            }
            #crosshair::before {
                width: 1px;
                height: 10px;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
            }
            #crosshair::after {
                width: 10px;
                height: 1px;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
            }
            .search-overlay {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.3);
                z-index: 999;
                display: none;
            }
            .search-overlay.active {
                display: block;
            }
        </style>
    </head>
    <body>
        <div class="search-overlay" id="searchOverlay"></div>
        <div id="info">Code Structure Explorer<br><span id="summary"></span></div>
        <div id="crosshair"></div>

        <div id="searchBox">
            <div id="searchContainer">
                <input type="text" id="searchInput" placeholder="Search symbols, files, types..." autocomplete="off">
                <button id="clearSearchBtn" title="Clear search"></button>
            </div>
        </div>

        <div id="legend">
            <div><strong>Symbol Types</strong></div>
            <div class="legend-item">
                <div class="legend-color" style="background: #e74c3c;"></div>
                <span>Module</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #f39c12;"></div>
                <span>Class</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #3498db;"></div>
                <span>Function</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #2ecc71;"></div>
                <span>Variable</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #9b59b6;"></div>
                <span>Interface</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background: #2c3e50;"></div>
                <span>File Node</span>
            </div>
            <div style="margin-top: 10px; padding-top: 8px; border-top: 1px solid rgba(255,255,255,0.3);">
                <div style="font-size: 10px; margin: 2px 0;"><strong>Controls:</strong></div>
                <div style="font-size: 10px; margin: 2px 0;">Drag: Free rotation</div>
                <div style="font-size: 10px; margin: 2px 0;">Scroll: Zoom in/out</div>
                <div style="font-size: 10px; margin: 2px 0;">Click: Select symbol</div>
                <div style="font-size: 10px; margin: 2px 0;">Click file: Focus file</div>
                <div style="font-size: 10px; margin: 2px 0;">Double-click: Open file</div>
                <div style="font-size: 10px; margin: 2px 0;">ESC: Clear all</div>
            </div>
        </div>

        <div id="fileFilter">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                <strong>Files</strong>
                <div>
                    <button id="selectAllFiles" style="font-size: 9px; padding: 2px 6px; margin-right: 4px;">Select All</button>
                    <button id="selectNoneFiles" style="font-size: 9px; padding: 2px 6px;">None</button>
                </div>
            </div>
            <div id="fileSearchBox">
                <input type="text" id="fileSearchInput" placeholder="Filter files..." autocomplete="off">
            </div>
            <div id="fileList"></div>
        </div>

        <div id="controls">
            <div><strong>Explorer Controls</strong></div>
            <button id="resetView">Reset View</button>
            <button id="fitToView">Fit All</button>
            <button id="focusSelected">Focus Selected</button>
            <br>
            <label>
                <input type="checkbox" id="showLabels" checked> Show Labels
            </label>
            <label>
                <input type="checkbox" id="showConnections" checked> Show Connections
            </label>
            <label>
                <input type="checkbox" id="autoRotate"> Auto Rotate
            </label>
            <br>
            <label>Node Size: <input type="range" id="nodeSize" min="0.3" max="2" step="0.1" value="1"></label>
            <label>Spacing: <input type="range" id="treeSpacing" min="0.5" max="2" step="0.1" value="1"></label>
            <div style="margin-top: 8px; padding: 6px; background: rgba(255,255,255,0.1); border-radius: 4px; font-size: 10px; color: #aaa;">
                Drag to rotate freely in any direction<br>
                ESC key: Clear search and selection
            </div>
        </div>

        <div id="searchResults"></div>

        <div id="stats">
            <div>Selected: <span id="selectedNode">None</span></div>
            <div>Files: <span id="fileCount">0</span></div>
            <div>Symbols: <span id="symbolCount">0</span></div>
            <div>Found: <span id="foundCount">-</span></div>
        </div>

        <script>
            function handleThreeJSLoadError() {
                console.error('Failed to load Three.js from /assets/three.min.js');
                document.getElementById('summary').textContent = 'Failed to load 3D library';

                // Try to load from CDN as fallback
                const script = document.createElement('script');
                script.src = 'https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js';
                script.onload = () => {
                    console.log('Three.js loaded from CDN');
                    waitForThree(() => {
                        console.log('THREE object is now available, initializing...');
                        init();
                    });
                };
                script.onerror = () => {
                    console.error('Failed to load Three.js from CDN as well');
                    document.getElementById('summary').textContent = 'Error: Cannot load 3D visualization';
                };
                document.head.appendChild(script);
            }

            function loadThreeJS() {
                // Try loading from local assets first
                const script = document.createElement('script');
                script.src = '/assets/three.min.js';
                script.onload = () => {
                    console.log('Three.js loaded successfully from assets');
                    waitForThree(() => {
                        console.log('THREE object is now available, initializing...');
                        init();
                    });
                };
                script.onerror = handleThreeJSLoadError;
                document.head.appendChild(script);
            }

            function waitForThree(callback) {
                if (typeof THREE !== 'undefined') {
                    console.log('THREE is defined, proceeding with initialization');
                    callback();
                } else {
                    console.log('Waiting for THREE to be defined...');
                    setTimeout(() => waitForThree(callback), 100);
                }
            }

            const LSP_DATA = ]] .. json_data .. [[;

            // Global text cleaning function to prevent encoding issues
            function safeName(text) {
                if (!text) return 'Unknown';
                // Convert to string and remove problematic characters
                let cleaned = String(text).replace(/[^\x20-\x7E]/g, '');
                return cleaned.trim() || 'Unknown';
            }

            let scene, camera, renderer;
            let nodes = [], searchResults = [];
            let nodeMeshes = [], connectionLines = [], labels = [];
            let raycaster, mouse;
            let selectedNode = null;
            let showLabels = true;
            let showConnections = true;
            let autoRotate = false;
            let nodeSize = 1.0;
            let treeSpacing = 1.0;
            let visitedNodes = new Set();

            let isMouseDown = false;
            let mouseX = 0, mouseY = 0;
            let sphericalCoords = {
                radius: 80, // Start further back
                theta: 0,    // horizontal rotation
                phi: Math.PI / 4  // Start at 45 degrees for better view
            };

            // Tree structure and filtering
            let fileStructure = {};
            let activeFiles = new Set(); // Files currently shown
            let currentSearchQuery = '';

            function init() {
                console.log('Initializing 3D visualization...');

                if (typeof THREE === 'undefined') {
                    console.error('THREE.js is not loaded');
                    document.getElementById('summary').textContent = 'THREE.js library not available';
                    return;
                }

                try {
                    console.log('THREE.js is available, creating 3D objects...');

                    scene = new THREE.Scene();
                    scene.background = new THREE.Color(0x1a1a1a);
                    console.log('Scene created');

                    camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 1000);
                    updateCameraPosition();
                    console.log('Camera created');

                    renderer = new THREE.WebGLRenderer({ antialias: true });
                    renderer.setSize(window.innerWidth, window.innerHeight);
                    renderer.setClearColor(0x1a1a1a);
                    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
                    document.body.appendChild(renderer.domElement);
                    console.log('Renderer created and added to DOM');

                    setupCameraControls();
                    console.log('Camera controls setup');

                    raycaster = new THREE.Raycaster();
                    mouse = new THREE.Vector2();
                    console.log('Raycaster and mouse initialized');

                    setupLighting();
                    console.log('Lighting setup');

                    setupEventListeners();
                    console.log('Event listeners setup');

                    loadTreeData();
                    console.log('Tree data loaded');

                    animate();
                    console.log('Animation loop started');

                    console.log('3D visualization initialized successfully');
                } catch (error) {
                    console.error('Error initializing scene:', error);
                    document.getElementById('summary').textContent = 'Error loading visualization: ' + error.message;
                }
            }

            function setupCameraControls() {
                renderer.domElement.addEventListener('mousedown', (event) => {
                    if (event.button === 0) { // Left mouse button
                        isMouseDown = true;
                        mouseX = event.clientX;
                        mouseY = event.clientY;
                        event.preventDefault();
                    }
                });

                document.addEventListener('mouseup', () => {
                    isMouseDown = false;
                });

                document.addEventListener('mousemove', (event) => {
                    if (isMouseDown) {
                        // Handle camera rotation with improved sensitivity
                        const deltaX = event.clientX - mouseX;
                        const deltaY = event.clientY - mouseY;

                        // Horizontal rotation (unlimited)
                        sphericalCoords.theta -= deltaX * 0.005;

                        sphericalCoords.phi += deltaY * 0.005;
                        // sphericalCoords.phi = Math.max(0.01, Math.min(Math.PI - 0.01, sphericalCoords.phi));

                        updateCameraPosition();

                        mouseX = event.clientX;
                        mouseY = event.clientY;
                    } else {
                        // Update mouse for raycasting
                        mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
                        mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

                        renderer.domElement.style.cursor = 'default';
                    }
                });

                renderer.domElement.addEventListener('wheel', (event) => {
                    const scale = event.deltaY > 0 ? 1.1 : 0.9;
                    sphericalCoords.radius *= scale;
                    sphericalCoords.radius = Math.max(5, Math.min(300, sphericalCoords.radius));
                    updateCameraPosition();
                    event.preventDefault();
                });
            }



            function updateCameraPosition() {
                camera.position.x = sphericalCoords.radius * Math.sin(sphericalCoords.phi) * Math.cos(sphericalCoords.theta);
                camera.position.y = sphericalCoords.radius * Math.cos(sphericalCoords.phi);
                camera.position.z = sphericalCoords.radius * Math.sin(sphericalCoords.phi) * Math.sin(sphericalCoords.theta);
                camera.lookAt(0, 0, 0);
            }

            function setupLighting() {
                const ambientLight = new THREE.AmbientLight(0x404040, 0.6);
                scene.add(ambientLight);

                const directionalLight1 = new THREE.DirectionalLight(0xffffff, 0.8);
                directionalLight1.position.set(10, 10, 5);
                scene.add(directionalLight1);

                const directionalLight2 = new THREE.DirectionalLight(0x4466aa, 0.4);
                directionalLight2.position.set(-10, -10, -5);
                scene.add(directionalLight2);
            }

            function setupEventListeners() {
                window.addEventListener('resize', onWindowResize, false);
                window.addEventListener('click', onMouseClick, false);
                window.addEventListener('dblclick', onDoubleClick, false);

                window.addEventListener('keydown', (event) => {
                    if (event.key === 'Escape') {
                        clearSearch();
                        clearVisited();
                        event.preventDefault();
                    }
                });

                document.getElementById('resetView').addEventListener('click', resetView);
                document.getElementById('fitToView').addEventListener('click', fitToView);
                document.getElementById('focusSelected').addEventListener('click', focusOnSelected);
                document.getElementById('selectAllFiles').addEventListener('click', selectAllFiles);
                document.getElementById('selectNoneFiles').addEventListener('click', selectNoneFiles);

                // File search
                document.getElementById('fileSearchInput').addEventListener('input', function(e) {
                    filterFileList(e.target.value);
                });

                document.getElementById('showLabels').addEventListener('change', function(e) {
                    showLabels = e.target.checked;
                    updateLabelsVisibility();
                });

                document.getElementById('showConnections').addEventListener('change', function(e) {
                    showConnections = e.target.checked;
                    updateConnectionsVisibility();
                });

                document.getElementById('autoRotate').addEventListener('change', function(e) {
                    autoRotate = e.target.checked;
                });

                document.getElementById('nodeSize').addEventListener('input', function(e) {
                    nodeSize = parseFloat(e.target.value);
                    updateNodeSizes();
                });

                document.getElementById('treeSpacing').addEventListener('input', function(e) {
                    treeSpacing = parseFloat(e.target.value);
                    rebuildTree();
                });

                // Improved search with debouncing and clear functionality
                const searchInput = document.getElementById('searchInput');
                const clearSearchBtn = document.getElementById('clearSearchBtn');
                const searchOverlay = document.getElementById('searchOverlay');

                let searchTimeout;

                searchInput.addEventListener('input', function(e) {
                    const value = e.target.value;
                    updateClearButtonVisibility(value);

                    clearTimeout(searchTimeout);
                    searchTimeout = setTimeout(() => {
                        performSearch(value);
                    }, 300); // 300ms debounce
                });

                searchInput.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && searchResults.length > 0) {
                        const firstItem = document.querySelector('.search-item.first-result');
                        if (firstItem) {
                            selectSearchResult(searchResults[0], firstItem);
                        }
                    }
                    if (e.key === 'Escape') {
                        clearSearch();
                    }
                });

                searchInput.addEventListener('focus', function() {
                    if (searchInput.value.trim()) {
                        showSearchOverlay(true);
                    }
                });

                // Clear search button
                clearSearchBtn.addEventListener('click', function() {
                    clearSearch();
                    searchInput.focus();
                });

                // Click outside to clear search
                searchOverlay.addEventListener('click', function() {
                    clearSearch();
                });

                // Prevent search from clearing when clicking on search elements
                document.getElementById('searchContainer').addEventListener('click', function(e) {
                    e.stopPropagation();
                });

                document.getElementById('searchResults').addEventListener('click', function(e) {
                    e.stopPropagation();
                });
            }

            function updateClearButtonVisibility(value) {
                const clearBtn = document.getElementById('clearSearchBtn');
                if (value.trim()) {
                    clearBtn.classList.add('show');
                } else {
                    clearBtn.classList.remove('show');
                }
            }

            function showSearchOverlay(show) {
                const overlay = document.getElementById('searchOverlay');
                if (show) {
                    overlay.classList.add('active');
                } else {
                    overlay.classList.remove('active');
                }
            }

            function loadTreeData() {
                const data = LSP_DATA;

                if (!data || !data.nodes) {
                    document.getElementById('summary').textContent = 'No data to visualize';
                    return;
                }

                nodes = data.nodes || [];

                buildFileStructure(nodes);
                buildFileList();

                // Show all files initially
                activeFiles = new Set(Object.keys(fileStructure));

                let summaryText = `${Object.keys(fileStructure).length} files, ${nodes.length} symbols`;
                document.getElementById('summary').textContent = summaryText;
                document.getElementById('fileCount').textContent = Object.keys(fileStructure).length;
                document.getElementById('symbolCount').textContent = nodes.length;

                clearScene();
                buildTreeVisualization();
            }

            function buildFileStructure(nodes) {
                fileStructure = {};

                nodes.forEach(node => {
                    const filename = node.filename || 'unknown';
                    if (!fileStructure[filename]) {
                        fileStructure[filename] = {
                            name: filename,
                            symbols: [],
                            position: { x: 0, y: 0, z: 0 }
                        };
                    }
                    fileStructure[filename].symbols.push(node);
                });
            }

            function buildFileList() {
                const fileList = document.getElementById('fileList');
                fileList.innerHTML = '';

                Object.keys(fileStructure).forEach(filename => {
                    const symbolCount = fileStructure[filename].symbols.length;
                    const fileItem = document.createElement('div');
                    fileItem.className = 'file-item active';
                    fileItem.dataset.filename = filename;

                    const checkbox = document.createElement('input');
                    checkbox.type = 'checkbox';
                    checkbox.className = 'file-checkbox';
                    checkbox.checked = true;
                    checkbox.addEventListener('change', (e) => {
                        e.stopPropagation();
                        toggleFileByCheckbox(filename, checkbox.checked);
                    });

                    const fileContent = document.createElement('div');
                    fileContent.className = 'file-content';
                    fileContent.innerHTML = `
                        <span style="flex: 1;">${filename}</span>
                        <span class="file-count">${symbolCount}</span>
                    `;

                    fileItem.appendChild(checkbox);
                    fileItem.appendChild(fileContent);

                    // Click on the file item (but not checkbox) to toggle
                    fileContent.addEventListener('click', () => {
                        checkbox.checked = !checkbox.checked;
                        toggleFileByCheckbox(filename, checkbox.checked);
                    });

                    fileList.appendChild(fileItem);
                });
            }

            function toggleFileByCheckbox(filename, isChecked) {
                const fileItem = document.querySelector(`[data-filename="${filename}"]`);
                if (isChecked) {
                    activeFiles.add(filename);
                    fileItem.classList.add('active');
                } else {
                    activeFiles.delete(filename);
                    fileItem.classList.remove('active');
                }
                rebuildTree();
            }

            function selectAllFiles() {
                activeFiles = new Set(Object.keys(fileStructure));
                document.querySelectorAll('.file-checkbox').forEach(checkbox => {
                    checkbox.checked = true;
                });
                document.querySelectorAll('.file-item').forEach(item => {
                    item.classList.add('active');
                });
                rebuildTree();
            }

            function selectNoneFiles() {
                activeFiles.clear();
                document.querySelectorAll('.file-checkbox').forEach(checkbox => {
                    checkbox.checked = false;
                });
                document.querySelectorAll('.file-item').forEach(item => {
                    item.classList.remove('active');
                });
                rebuildTree();
            }

            function filterFileList(query) {
                const lowerQuery = query.toLowerCase();
                document.querySelectorAll('.file-item').forEach(item => {
                    const filename = item.dataset.filename;
                    if (!query.trim() || filename.toLowerCase().includes(lowerQuery)) {
                        item.classList.remove('hidden');
                    } else {
                        item.classList.add('hidden');
                    }
                });
            }

            function buildTreeVisualization() {
                const activeFileList = Array.from(activeFiles);

                if (activeFileList.length === 0) {
                    return; // No files to display
                }

                // Special layout for single file mode
                if (activeFileList.length === 1) {
                    const filename = activeFileList[0];
                    fileStructure[filename].position = { x: 0, y: 15, z: 0 }; // Elevate file node

                    // Create file root node at elevated position
                    createFileNode(fileStructure[filename], 0);

                    // Create symbols in a 3D spiral/layered layout for single file
                    const symbols = fileStructure[filename].symbols;
                    const symbolSpacing = 8 * treeSpacing;

                    if (symbols.length <= 10) {
                        // Simple circle for small number of symbols
                        symbols.forEach((symbol, symbolIndex) => {
                            const angle = (symbolIndex / symbols.length) * Math.PI * 2;
                            const radius = 12;

                            const symbolX = Math.cos(angle) * radius;
                            const symbolY = 0;
                            const symbolZ = Math.sin(angle) * radius;

                            createSymbolNode(symbol, { x: symbolX, y: symbolY, z: symbolZ }, symbolIndex);

                            // Create connection from file to symbol
                            if (showConnections) {
                                createConnection(
                                    fileStructure[filename].position,
                                    { x: symbolX, y: symbolY, z: symbolZ }
                                );
                            }
                        });
                    } else {
                        // Multi-layer spiral for many symbols
                        const symbolsPerLayer = 8;
                        const layerHeight = 6;

                        symbols.forEach((symbol, symbolIndex) => {
                            const layer = Math.floor(symbolIndex / symbolsPerLayer);
                            const indexInLayer = symbolIndex % symbolsPerLayer;
                            const angleOffset = layer * 0.3; // Slight rotation per layer

                            const angle = (indexInLayer / symbolsPerLayer) * Math.PI * 2 + angleOffset;
                            const radius = 15 + layer * 3; // Increase radius per layer

                            const symbolX = Math.cos(angle) * radius;
                            const symbolY = -layer * layerHeight;
                            const symbolZ = Math.sin(angle) * radius;

                            createSymbolNode(symbol, { x: symbolX, y: symbolY, z: symbolZ }, symbolIndex);

                            // Create connection from file to symbol
                            if (showConnections) {
                                createConnection(
                                    fileStructure[filename].position,
                                    { x: symbolX, y: symbolY, z: symbolZ }
                                );
                            }
                        });
                    }
                } else {
                    // Multi-file layout (original code)
                    const filesPerRow = Math.ceil(Math.sqrt(activeFileList.length));
                    const fileSpacing = 25 * treeSpacing;

                    // Position files in a grid
                    activeFileList.forEach((filename, fileIndex) => {
                        const row = Math.floor(fileIndex / filesPerRow);
                        const col = fileIndex % filesPerRow;

                        const fileX = (col - filesPerRow / 2) * fileSpacing;
                        const fileZ = (row - filesPerRow / 2) * fileSpacing;

                        fileStructure[filename].position = { x: fileX, y: 0, z: fileZ };

                        // Create file root node
                        createFileNode(fileStructure[filename], fileIndex);

                        // Create symbols for this file
                        const symbols = fileStructure[filename].symbols;
                        const symbolsPerRow = Math.ceil(Math.sqrt(symbols.length));
                        const symbolSpacing = 4 * treeSpacing;

                        symbols.forEach((symbol, symbolIndex) => {
                            const symbolRow = Math.floor(symbolIndex / symbolsPerRow);
                            const symbolCol = symbolIndex % symbolsPerRow;

                            const symbolX = fileX + (symbolCol - symbolsPerRow / 2) * symbolSpacing;
                            const symbolY = -8 - symbolRow * 5 * treeSpacing;
                            const symbolZ = fileZ + (symbolRow - symbolsPerRow / 2) * symbolSpacing * 0.5;

                            createSymbolNode(symbol, { x: symbolX, y: symbolY, z: symbolZ }, symbolIndex);

                            // Create connection from file to symbol
                            if (showConnections) {
                                createConnection(
                                    fileStructure[filename].position,
                                    { x: symbolX, y: symbolY, z: symbolZ }
                                );
                            }
                        });
                    });
                }

                updateLabelsVisibility();
                updateConnectionsVisibility();
            }

            function createFileNode(fileData, index) {
                const geometry = new THREE.BoxGeometry(4 * nodeSize, 2.5 * nodeSize, 4 * nodeSize);
                const material = new THREE.MeshPhongMaterial({
                    color: 0x2c3e50,
                    emissive: 0x111822,
                    transparent: true,
                    opacity: 0.9,
                    shininess: 100
                });

                const mesh = new THREE.Mesh(geometry, material);
                mesh.position.set(fileData.position.x, fileData.position.y, fileData.position.z);
                mesh.userData = {
                    type: 'file',
                    data: fileData,
                    index: index
                };

                scene.add(mesh);
                nodeMeshes.push(mesh);

                createHighResLabel(mesh, fileData.name, 'file');
            }

            function focusOnSingleFile(filename) {
                console.log('Focusing on single file:', filename);

                // Update the file filter UI to show only this file is selected
                document.querySelectorAll('.file-checkbox').forEach(checkbox => {
                    const item = checkbox.closest('.file-item');
                    const itemFilename = item.dataset.filename;

                    if (itemFilename === filename) {
                        checkbox.checked = true;
                        item.classList.add('active');
                    } else {
                        checkbox.checked = false;
                        item.classList.remove('active');
                    }
                });

                // Set activeFiles to only include this file
                activeFiles.clear();
                activeFiles.add(filename);

                // Add a visual indicator that we're in single-file mode
                const info = document.getElementById('info');
                info.innerHTML = `Code Structure Explorer - Viewing: ${filename}<br><span id="summary">Symbols in this file</span>`;

                // Update stats
                const symbolCount = fileStructure[filename] ? fileStructure[filename].symbols.length : 0;
                document.getElementById('fileCount').textContent = '1';
                document.getElementById('symbolCount').textContent = symbolCount;
                document.getElementById('summary').textContent = `${symbolCount} symbols in ${filename}`;

                // Add a "Show All Files" button temporarily
                if (!document.getElementById('showAllFilesBtn')) {
                    const showAllBtn = document.createElement('button');
                    showAllBtn.id = 'showAllFilesBtn';
                    showAllBtn.textContent = 'Show All Files';
                    showAllBtn.style.cssText = `
                        position: absolute;
                        top: 120px;
                        left: 50%;
                        transform: translateX(-50%);
                        background: linear-gradient(45deg, #e74c3c 0%, #c0392b 100%);
                        border: none;
                        color: white;
                        padding: 10px 20px;
                        border-radius: 8px;
                        cursor: pointer;
                        font-size: 14px;
                        font-weight: bold;
                        z-index: 1001;
                        box-shadow: 0 4px 15px rgba(231, 76, 60, 0.3);
                        transition: all 0.3s ease;
                    `;
                    showAllBtn.addEventListener('click', returnToAllFiles);
                    showAllBtn.addEventListener('mouseenter', function() {
                        this.style.transform = 'translateX(-50%) translateY(-2px)';
                        this.style.boxShadow = '0 6px 20px rgba(231, 76, 60, 0.4)';
                    });
                    showAllBtn.addEventListener('mouseleave', function() {
                        this.style.transform = 'translateX(-50%)';
                        this.style.boxShadow = '0 4px 15px rgba(231, 76, 60, 0.3)';
                    });
                    document.body.appendChild(showAllBtn);
                }

                // Rebuild the tree with only this file
                rebuildTree();

                // Auto-fit to the single file view with better angle
                setTimeout(() => {
                    // Set a better viewing angle for single file
                    sphericalCoords.theta = Math.PI / 6; // 30 degrees
                    sphericalCoords.phi = Math.PI / 5;   // 36 degrees
                    sphericalCoords.radius = 50;         // Closer view
                    updateCameraPosition();
                }, 500);
            }

            function returnToAllFiles() {
                console.log('Returning to all files view');

                // Remove the "Show All Files" button
                const showAllBtn = document.getElementById('showAllFilesBtn');
                if (showAllBtn) {
                    showAllBtn.remove();
                }

                // Restore original title
                const info = document.getElementById('info');
                info.innerHTML = 'Code Structure Explorer<br><span id="summary"></span>';

                // Select all files again
                selectAllFiles();

                // Update summary
                const totalFiles = Object.keys(fileStructure).length;
                const totalSymbols = nodes.length;
                document.getElementById('summary').textContent = `${totalFiles} files, ${totalSymbols} symbols`;
                document.getElementById('fileCount').textContent = totalFiles;
                document.getElementById('symbolCount').textContent = totalSymbols;
            }

            function createSymbolNode(symbol, position, index) {
                const size = Math.max((symbol.size || 1) * nodeSize, 0.5);
                const color = getColorByType(symbol.symbolType);
                const emissiveColor = getEmissiveColor(symbol.symbolType);

                // Different shapes for different symbol types
                let geometry;
                switch (symbol.symbolType) {
                    case 'class':
                    case 'struct':
                        geometry = new THREE.BoxGeometry(size * 1.5, size * 1.5, size * 1.5);
                        break;
                    case 'function':
                    case 'method':
                        geometry = new THREE.SphereGeometry(size, 16, 12);
                        break;
                    case 'variable':
                    case 'field':
                        geometry = new THREE.CylinderGeometry(size * 0.8, size * 0.8, size * 1.2, 12);
                        break;
                    case 'interface':
                        geometry = new THREE.OctahedronGeometry(size, 1);
                        break;
                    case 'enum':
                        geometry = new THREE.DodecahedronGeometry(size * 0.8, 0);
                        break;
                    case 'constant':
                        geometry = new THREE.TetrahedronGeometry(size, 0);
                        break;
                    default:
                        geometry = new THREE.IcosahedronGeometry(size * 0.9, 0);
                }

                const material = new THREE.MeshPhongMaterial({
                    color: color,
                    emissive: emissiveColor,
                    transparent: true,
                    opacity: 0.95,
                    shininess: 80
                });

                const mesh = new THREE.Mesh(geometry, material);
                mesh.position.set(position.x, position.y, position.z);
                mesh.userData = {
                    type: 'symbol',
                    data: symbol,
                    index: index
                };

                // Create truly unique ID with position info - use safe names
                mesh.id = `symbol_${safeName(symbol.name)}_${safeName(symbol.filename)}_${Math.round(position.x)}_${Math.round(position.y)}_${Math.round(position.z)}`;
                mesh.name = `${safeName(symbol.name)}_in_${safeName(symbol.filename)}`; // Also set the name property

                console.log(`Created symbol mesh: ${mesh.id} for symbol "${safeName(symbol.name)}" at position (${position.x}, ${position.y}, ${position.z})`);

                scene.add(mesh);
                nodeMeshes.push(mesh);

                createHighResLabel(mesh, symbol.name, 'symbol');
            }

            function createConnection(pos1, pos2) {
                const material = new THREE.LineBasicMaterial({
                    color: 0x666666,
                    transparent: true,
                    opacity: 0.5
                });

                const geometry = new THREE.BufferGeometry();
                const positions = new Float32Array([
                    pos1.x, pos1.y, pos1.z,
                    pos2.x, pos2.y, pos2.z
                ]);
                geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

                const line = new THREE.Line(geometry, material);
                scene.add(line);
                connectionLines.push(line);
            }

            function createHighResLabel(mesh, text, type) {
                const canvas = document.createElement('canvas');
                const context = canvas.getContext('2d');

                // Higher resolution for sharper text
                const scaleFactor = 3;
                canvas.width = 240 * scaleFactor;
                canvas.height = 60 * scaleFactor;
                context.scale(scaleFactor, scaleFactor);

                // Background with better colors
                const gradient = context.createLinearGradient(0, 0, 240, 60);
                if (type === 'file') {
                    gradient.addColorStop(0, 'rgba(44, 62, 80, 0.95)');
                    gradient.addColorStop(1, 'rgba(52, 73, 94, 0.95)');
                } else {
                    gradient.addColorStop(0, 'rgba(44, 62, 80, 0.95)');
                    gradient.addColorStop(1, 'rgba(52, 73, 94, 0.95)');
                }

                context.fillStyle = gradient;
                context.fillRect(0, 0, 240, 60);

                // Border
                context.strokeStyle = 'rgba(255, 255, 255, 0.6)';
                context.lineWidth = 2;
                context.strokeRect(1, 1, 238, 58);

                // Text with better rendering - use safeName for consistent text processing
                context.fillStyle = 'white';
                context.textAlign = 'center';
                context.textBaseline = 'middle';
                context.shadowColor = 'rgba(0, 0, 0, 0.8)';
                context.shadowBlur = 2;

                // Use safeName for consistent text processing
                let displayText = safeName(text);

                if (displayText.length > 20) {
                    displayText = displayText.substring(0, 17) + '...';
                }

                // Fallback should not be needed with safeName, but keep it for safety
                if (!displayText.trim()) {
                    displayText = type === 'file' ? '[File]' : '[Symbol]';
                }

                context.font = type === 'file' ? 'bold 16px Arial' : '13px Arial';

                try {
                    context.fillText(displayText, 120, 30);
                } catch (e) {
                    // Simple fallback for any rendering issues
                    console.warn('Text rendering failed for:', text, 'using fallback');
                    context.fillText(type === 'file' ? '[File]' : '[Symbol]', 120, 30);
                }

                const texture = new THREE.CanvasTexture(canvas);
                texture.generateMipmaps = false;
                texture.minFilter = THREE.LinearFilter;
                texture.magFilter = THREE.LinearFilter;

                const material = new THREE.SpriteMaterial({
                    map: texture,
                    transparent: true,
                    opacity: 0.95,
                    depthTest: false
                });
                const sprite = new THREE.Sprite(material);
                sprite.scale.set(10, 2.5, 1);
                sprite.position.copy(mesh.position);

                if (type === 'file') {
                    sprite.position.y += 5;
                    sprite.position.z += 2;
                } else {
                    sprite.position.y += 3.5;
                    sprite.position.z += 1.5;
                }

                sprite.userData = { text: displayText, type: type };

                scene.add(sprite);
                labels.push(sprite);
            }

            function getColorByType(symbolType) {
                const colorMap = {
                    'module': 0xe74c3c,      // red
                    'package': 0xe67e22,     // orange
                    'class': 0xf39c12,       // yellow
                    'struct': 0xd35400,      // deep orange
                    'function': 0x3498db,    // blue
                    'method': 0x2980b9,      // deep blue
                    'variable': 0x2ecc71,    // green
                    'field': 0x27ae60,       // deep green
                    'interface': 0x9b59b6,   // violet
                    'enum': 0x8e44ad,        // deep violet
                    'constant': 0xf1c40f,    // golden yellow
                    'constructor': 0xe67e22, // oragne
                    'property': 0x1abc9c,    // cyan
                    'namespace': 0x34495e,   // grey blue
                    'type_parameter': 0xb37feb
                };
                return colorMap[symbolType] || 0x4ecdc4;
            }

            function getEmissiveColor(symbolType) {
                const emissiveMap = {
                    'module': 0x441111,
                    'package': 0x442211,
                    'class': 0x443311,
                    'struct': 0x331100,
                    'function': 0x112244,
                    'method': 0x002244,
                    'variable': 0x114422,
                    'field': 0x003322,
                    'interface': 0x331144,
                    'enum': 0x221133,
                    'constant': 0x443300,
                    'constructor': 0x442211,
                    'property': 0x113344,
                    'namespace': 0x222233,
                    'type_parameter': 0x332244
                };
                return emissiveMap[symbolType] || 0x113344;
            }

            function performSearch(query) {
                currentSearchQuery = query;
                const resultsDiv = document.getElementById('searchResults');

                if (!query.trim()) {
                    clearSearch();
                    return;
                }

                // Show search overlay
                showSearchOverlay(true);

                // Reset without flicker
                nodeMeshes.forEach(mesh => {
                    if (mesh.userData.type === 'symbol') {
                        mesh.material.emissive.setHex(0x000000);
                        mesh.material.emissiveIntensity = 0;
                        mesh.scale.set(1, 1, 1);
                    }
                });

                searchResults = [];
                const lowerQuery = query.toLowerCase();

                console.log('=== Starting search for:', query, '===');

                nodeMeshes.forEach((mesh, meshIndex) => {
                    if (mesh.userData.type === 'symbol') {
                        const symbol = mesh.userData.data;

                        // Use safe names for searching to avoid encoding issues
                        const safeName1 = safeName(symbol.name).toLowerCase();
                        const safeFilename = safeName(symbol.filename).toLowerCase();
                        const safeType = safeName(symbol.symbolType).toLowerCase();

                        // More precise matching with cleaned names
                        const nameMatch = safeName1.includes(lowerQuery);
                        const fileMatch = safeFilename.includes(lowerQuery);
                        const typeMatch = safeType.includes(lowerQuery);

                        if (nameMatch || fileMatch || typeMatch) {
                            mesh.material.emissive.setHex(0xe67e22);
                            mesh.material.emissiveIntensity = 0.7;
                            mesh.scale.set(1.2, 1.2, 1.2);

                            const score = getSearchScore(symbol, lowerQuery);

                            searchResults.push({
                                symbol: symbol,
                                mesh: mesh,
                                score: score,
                                matchType: nameMatch ? 'name' : (fileMatch ? 'file' : 'type')
                            });

                            console.log(`Found match #${searchResults.length}:`, {
                                name: safeName(symbol.name),
                                meshId: mesh.id,
                                meshIndex: meshIndex,
                                score: score,
                                matchType: nameMatch ? 'name' : (fileMatch ? 'file' : 'type'),
                                position: mesh.position
                            });
                        }
                    }
                });

                // Sort by relevance - exact name matches first
                searchResults.sort((a, b) => {
                    // Exact name match gets highest priority
                    const aExact = safeName(a.symbol.name).toLowerCase() === lowerQuery ? 1000 : 0;
                    const bExact = safeName(b.symbol.name).toLowerCase() === lowerQuery ? 1000 : 0;

                    if (aExact !== bExact) return bExact - aExact;

                    // Then by match type (name > file > type)
                    const aTypeScore = a.matchType === 'name' ? 100 : (a.matchType === 'file' ? 50 : 10);
                    const bTypeScore = b.matchType === 'name' ? 100 : (b.matchType === 'file' ? 50 : 10);

                    if (aTypeScore !== bTypeScore) return bTypeScore - aTypeScore;

                    // Finally by calculated score
                    return b.score - a.score;
                });

                console.log('Search results after sorting:');
                searchResults.forEach((result, idx) => {
                    console.log(`${idx + 1}. ${safeName(result.symbol.name)} (${result.matchType}) - mesh: ${result.mesh.id}`);
                });

                // Update UI
                document.getElementById('foundCount').textContent = searchResults.length;

                if (searchResults.length > 0) {
                    showSearchResults(searchResults.slice(0, 8));
                } else {
                    resultsDiv.style.display = 'none';
                }
            }

            function getSearchScore(symbol, query) {
                let score = 0;
                const name = safeName(symbol.name).toLowerCase();
                const lowerQuery = query.toLowerCase();

                // Exact match gets highest score
                if (name === lowerQuery) score += 1000;
                else if (name.startsWith(lowerQuery)) score += 500;
                else if (name.includes(lowerQuery)) {
                    // Boost shorter names that contain the query
                    const nameLength = name.length;
                    const queryLength = lowerQuery.length;
                    score += Math.max(100 - (nameLength - queryLength) * 5, 20);
                }

                // Bonus for type and file matches
                const symbolType = safeName(symbol.symbolType).toLowerCase();
                const filename = safeName(symbol.filename).toLowerCase();

                if (symbolType.includes(lowerQuery)) score += 10;
                if (filename.includes(lowerQuery)) score += 5;

                return score;
            }

            function showSearchResults(results) {
                const resultsDiv = document.getElementById('searchResults');
                resultsDiv.innerHTML = '<div style="font-weight: bold; margin-bottom: 8px; color: #4a90e2;">Search Results:</div>';

                results.forEach((result, index) => {
                    const item = document.createElement('div');
                    item.className = 'search-item';
                    if (index === 0) item.classList.add('first-result');

                    // More detailed display with safe text
                    const matchInfo = result.matchType === 'name' ? 'Name match' :
                                     result.matchType === 'file' ? 'File match' :
                                     'Type match';

                    const symbolName = safeName(result.symbol.name);
                    const symbolType = safeName(result.symbol.symbolType) || 'symbol';
                    const fileName = safeName(result.symbol.filename);

                    item.innerHTML = `
                        <div style="font-weight: bold;">${symbolName}</div>
                        <div style="font-size: 10px; color: #aaa;">${symbolType} in ${fileName}</div>
                        <div style="font-size: 9px; color: #888;">${matchInfo} (score: ${result.score})</div>
                    `;
                    item.addEventListener('click', (event) => {
                        console.log('Clicked search result:', safeName(result.symbol.name));
                        selectSearchResult(result, item);
                    });
                    resultsDiv.appendChild(item);
                });

                resultsDiv.style.display = 'block';
            }

            function selectSearchResult(result, clickedElement) {
                console.log('=== Selecting search result ===');
                console.log('Result symbol name:', safeName(result.symbol.name));
                console.log('Result mesh id:', result.mesh.id);
                console.log('Result mesh position:', result.mesh.position.x, result.mesh.position.y, result.mesh.position.z);
                console.log('Result mesh userData:', result.mesh.userData);

                // Clear previous selection in UI
                document.querySelectorAll('.search-item').forEach(item => {
                    item.classList.remove('selected');
                });

                // Select this result in UI
                clickedElement.classList.add('selected');

                // Verify the mesh is correct by checking multiple properties
                const targetMesh = result.mesh;
                const meshSymbol = targetMesh.userData.data;

                console.log('Verifying mesh...');
                console.log('Expected symbol name:', safeName(result.symbol.name));
                console.log('Mesh symbol name:', safeName(meshSymbol.name));
                console.log('Expected file:', safeName(result.symbol.filename));
                console.log('Mesh file:', safeName(meshSymbol.filename));

                if (safeName(meshSymbol.name) !== safeName(result.symbol.name) || safeName(meshSymbol.filename) !== safeName(result.symbol.filename)) {
                    console.error('❌ MESH MISMATCH DETECTED!');
                    console.error('Expected:', safeName(result.symbol.name), 'in', safeName(result.symbol.filename));
                    console.error('Got:', safeName(meshSymbol.name), 'in', safeName(meshSymbol.filename));

                    // Try to find the correct mesh by name and filename
                    console.log('🔍 Searching for correct mesh...');
                    const correctMesh = nodeMeshes.find(m =>
                        m.userData.type === 'symbol' &&
                        safeName(m.userData.data.name) === safeName(result.symbol.name) &&
                        safeName(m.userData.data.filename) === safeName(result.symbol.filename)
                    );

                    if (correctMesh) {
                        console.log('✅ Found correct mesh:', correctMesh.id);
                        console.log('✅ Correct position:', correctMesh.position.x, correctMesh.position.y, correctMesh.position.z);
                        focusOnNode(correctMesh);
                        selectNode(correctMesh);
                        return;
                    } else {
                        console.error('❌ Could not find correct mesh!');
                        // List all meshes with this symbol name for debugging
                        const sameName = nodeMeshes.filter(m =>
                            m.userData.type === 'symbol' &&
                            safeName(m.userData.data.name) === safeName(result.symbol.name)
                        );
                        console.log('All meshes with name "' + safeName(result.symbol.name) + '":', sameName.map(m => ({
                            id: m.id,
                            file: safeName(m.userData.data.filename),
                            position: { x: m.position.x, y: m.position.y, z: m.position.z }
                        })));
                    }
                }

                console.log('✅ Mesh verification passed, proceeding with selection...');

                // Use the verified mesh
                focusOnNode(targetMesh);
                selectNode(targetMesh);
            }

            function clearSearch() {
                const searchInput = document.getElementById('searchInput');
                const resultsDiv = document.getElementById('searchResults');

                searchInput.value = '';
                resultsDiv.style.display = 'none';
                document.getElementById('foundCount').textContent = '-';
                currentSearchQuery = '';

                // Hide overlay and clear button
                showSearchOverlay(false);
                updateClearButtonVisibility('');

                // Reset all symbol highlights
                nodeMeshes.forEach(mesh => {
                    if (mesh.userData.type === 'symbol') {
                        mesh.material.emissive.setHex(0x000000);
                        mesh.material.emissiveIntensity = 0;
                        mesh.scale.set(1, 1, 1);
                    }
                });

                searchResults = [];

                // Blur the search input to remove focus
                searchInput.blur();
            }

            function focusOnNode(mesh) {
                if (!mesh) {
                    console.error('focusOnNode: No mesh provided');
                    return;
                }

                console.log('=== focusOnNode called ===');
                console.log('Target mesh id:', mesh.id);
                console.log('Target symbol:', safeName(mesh.userData.data.name));
                console.log('Target position:', mesh.position.x, mesh.position.y, mesh.position.z);

                const targetPos = mesh.position.clone();
                console.log('Cloned target position:', targetPos.x, targetPos.y, targetPos.z);

                // Calculate optimal viewing position - much closer to the target
                const distance = 15; // Closer distance
                const offsetX = 10;   // Small offset to view from an angle
                const offsetY = 5;    // Slightly above
                const offsetZ = 10;   // Some depth

                const newCameraPos = new THREE.Vector3(
                    targetPos.x + offsetX,
                    targetPos.y + offsetY,
                    targetPos.z + offsetZ
                );

                console.log('Calculated camera position:', newCameraPos.x, newCameraPos.y, newCameraPos.z);
                console.log('Current camera position:', camera.position.x, camera.position.y, camera.position.z);

                // Animate to the new position
                const startPos = camera.position.clone();
                const startTime = Date.now();
                const duration = 1500; // 1.5 seconds for smoother animation

                function animateCamera() {
                    const elapsed = Date.now() - startTime;
                    const progress = Math.min(elapsed / duration, 1);
                    const eased = 1 - Math.pow(1 - progress, 3); // easeOut cubic

                    // Interpolate camera position
                    camera.position.lerpVectors(startPos, newCameraPos, eased);

                    // Always look at the target
                    camera.lookAt(targetPos);

                    console.log(`Animation progress: ${(progress * 100).toFixed(1)}% - Camera at: (${camera.position.x.toFixed(1)}, ${camera.position.y.toFixed(1)}, ${camera.position.z.toFixed(1)})`);

                    if (progress < 1) {
                        requestAnimationFrame(animateCamera);
                    } else {
                        console.log('✅ Camera animation completed. Final position:', camera.position.x, camera.position.y, camera.position.z);
                        console.log('✅ Looking at target:', targetPos.x, targetPos.y, targetPos.z);

                        // Verify we're looking at the right place
                        const direction = new THREE.Vector3();
                        camera.getWorldDirection(direction);
                        console.log('Camera direction:', direction.x, direction.y, direction.z);
                    }
                }

                console.log('Starting camera animation...');
                animateCamera();
            }

            function clearScene() {
                nodeMeshes.forEach(mesh => scene.remove(mesh));
                connectionLines.forEach(line => scene.remove(line));
                labels.forEach(label => scene.remove(label));

                nodeMeshes = [];
                connectionLines = [];
                labels = [];
            }

            function updateLabelsVisibility() {
                labels.forEach(label => {
                    label.visible = showLabels;
                });
            }

            function updateConnectionsVisibility() {
                connectionLines.forEach(line => {
                    line.visible = showConnections;
                });
            }

            function updateNodeSizes() {
                clearScene();
                buildTreeVisualization();
            }

            function rebuildTree() {
                clearScene();
                buildTreeVisualization();

                // Re-apply search if there was one
                if (currentSearchQuery) {
                    setTimeout(() => {
                        performSearch(currentSearchQuery);
                    }, 100);
                }
            }

            function onMouseClick(event) {
                // Don't handle clicks when search overlay is active
                if (document.getElementById('searchOverlay').classList.contains('active')) {
                    return;
                }

                raycaster.setFromCamera(mouse, camera);

                // Check for clicks on both meshes and labels
                const allObjects = [...nodeMeshes, ...labels];
                const intersects = raycaster.intersectObjects(allObjects);

                if (intersects.length > 0) {
                    const clickedObject = intersects[0].object;

                    // Check if clicked object is a file label (sprite)
                    if (clickedObject.userData && clickedObject.userData.type === 'file') {
                        // Find the corresponding file mesh
                        const labelIndex = labels.indexOf(clickedObject);
                        if (labelIndex !== -1) {
                            // Find the corresponding file mesh
                            const fileMesh = nodeMeshes.find(mesh =>
                                mesh.userData.type === 'file' &&
                                Math.abs(mesh.position.x - clickedObject.position.x) < 1 &&
                                Math.abs(mesh.position.z - clickedObject.position.z) < 1
                            );

                            if (fileMesh && fileMesh.userData.data) {
                                const filename = safeName(fileMesh.userData.data.name);
                                console.log('Clicked on file label:', filename);
                                focusOnSingleFile(filename);
                                return;
                            }
                        }
                    }

                    // Handle regular mesh clicks (both file and symbol meshes)
                    if (clickedObject.userData && clickedObject.userData.type) {
                        if (clickedObject.userData.type === 'file') {
                            const filename = safeName(clickedObject.userData.data.name);
                            console.log('Clicked on file mesh:', filename);
                            focusOnSingleFile(filename);
                        } else if (clickedObject.userData.type === 'symbol') {
                            selectNode(clickedObject);
                        }
                    }
                }
            }

            function onDoubleClick(event) {
                // Don't handle clicks when search overlay is active
                if (document.getElementById('searchOverlay').classList.contains('active')) {
                    return;
                }

                raycaster.setFromCamera(mouse, camera);
                const allObjects = [...nodeMeshes, ...labels];
                const intersects = raycaster.intersectObjects(allObjects);

                if (intersects.length > 0) {
                    const clickedObject = intersects[0].object;

                    // Handle double-click on file labels or meshes
                    if (clickedObject.userData && clickedObject.userData.type === 'file') {
                        // For file double-click, focus on the file (same as single click)
                        let filename;
                        if (clickedObject.userData.data) {
                            filename = safeName(clickedObject.userData.data.name);
                        } else {
                            // If it's a label, find the corresponding file mesh
                            const labelIndex = labels.indexOf(clickedObject);
                            if (labelIndex !== -1) {
                                const fileMesh = nodeMeshes.find(mesh =>
                                    mesh.userData.type === 'file' &&
                                    Math.abs(mesh.position.x - clickedObject.position.x) < 1 &&
                                    Math.abs(mesh.position.z - clickedObject.position.z) < 1
                                );
                                if (fileMesh && fileMesh.userData.data) {
                                    filename = safeName(fileMesh.userData.data.name);
                                }
                            }
                        }

                        if (filename) {
                            console.log('Double-clicked on file:', filename);
                            focusOnSingleFile(filename);
                        }
                    } else if (clickedObject.userData && clickedObject.userData.type === 'symbol') {
                        // For symbol double-click, open the file
                        openFile(clickedObject.userData.data);
                    }
                }
            }

            function selectNode(mesh) {
                console.log('=== selectNode called ===');
                console.log('Target mesh id:', mesh.id);
                console.log('Target mesh userData:', mesh.userData);
                console.log('Target symbol name:', safeName(mesh.userData.data.name));
                console.log('Target mesh position:', mesh.position.x, mesh.position.y, mesh.position.z);

                selectedNode = mesh.userData.data;

                // FORCE reset ALL nodes first - more aggressive approach
                console.log('🔄 Resetting all nodes...');
                let resetCount = 0;
                nodeMeshes.forEach((m, idx) => {
                    if (m.userData.type === 'symbol') {
                        // Force reset material
                        m.material.emissive.setHex(0x000000);
                        m.material.emissiveIntensity = 0;
                        m.scale.set(1, 1, 1);
                        m.material.needsUpdate = true;
                        resetCount++;
                    } else if (m.userData.type === 'file') {
                        m.material.emissive.setHex(0x000000);
                        m.material.emissiveIntensity = 0;
                        m.material.needsUpdate = true;
                    }
                });
                console.log(`✅ Reset ${resetCount} symbol nodes`);

                // Re-apply search highlights
                if (searchResults.length > 0) {
                    console.log('🔍 Re-applying search highlights...');
                    searchResults.forEach((result, idx) => {
                        result.mesh.material.emissive.setHex(0xe67e22);
                        result.mesh.material.emissiveIntensity = 0.7;
                        result.mesh.scale.set(1.2, 1.2, 1.2);
                        result.mesh.material.needsUpdate = true;
                        console.log(`  ${idx + 1}. Search highlight: ${safeName(result.symbol.name)} (mesh: ${result.mesh.id})`);
                    });
                }

                // NOW apply the selection highlight - FORCE it
                console.log('⭐ Applying WHITE selection highlight...');
                if (mesh.userData.type === 'symbol') {
                    const symbolName = safeName(mesh.userData.data.name);
                    console.log('Target for WHITE highlight:', symbolName);

                    // Find the mesh in our array to make sure we have the right reference
                    const meshIndex = nodeMeshes.indexOf(mesh);
                    console.log('Mesh index in nodeMeshes array:', meshIndex);

                    if (meshIndex === -1) {
                        console.error('❌ Mesh not found in nodeMeshes array!');
                        // Try to find it by ID
                        const foundMesh = nodeMeshes.find(m => m.id === mesh.id);
                        if (foundMesh) {
                            console.log('✅ Found mesh by ID, using that instead');
                            mesh = foundMesh;
                        }
                    }

                    // FORCE the selection highlight with better colors
                    mesh.material.emissive.setHex(0xffd700);
                    mesh.material.emissiveIntensity = 0.8;
                    mesh.scale.set(1.5, 1.5, 1.5);
                    mesh.material.needsUpdate = true;

                    // Also make sure it's not transparent
                    mesh.material.opacity = 1.0;
                    mesh.visible = true;

                    document.getElementById('selectedNode').textContent = safeName(selectedNode.name);

                    console.log('✅ Applied WHITE highlight to:', symbolName);
                    console.log('✅ Position:', mesh.position.x, mesh.position.y, mesh.position.z);
                    console.log('✅ Scale:', mesh.scale.x, mesh.scale.y, mesh.scale.z);
                    console.log('✅ Emissive color hex:', mesh.material.emissive.getHex().toString(16));
                    console.log('✅ Emissive intensity:', mesh.material.emissiveIntensity);
                    console.log('✅ Material opacity:', mesh.material.opacity);
                    console.log('✅ Mesh visible:', mesh.visible);

                    // Double-check: look for any other mesh at the same position (duplicates)
                    const samePosition = nodeMeshes.filter(m =>
                        m.userData.type === 'symbol' &&
                        Math.abs(m.position.x - mesh.position.x) < 0.1 &&
                        Math.abs(m.position.y - mesh.position.y) < 0.1 &&
                        Math.abs(m.position.z - mesh.position.z) < 0.1
                    );

                    if (samePosition.length > 1) {
                        console.warn(`⚠️ Found ${samePosition.length} meshes at similar position:`);
                        samePosition.forEach((dupMesh, idx) => {
                            console.warn(`  ${idx + 1}. ${safeName(dupMesh.userData.data.name)} (mesh: ${dupMesh.id})`);
                            if (dupMesh !== mesh) {
                                // Apply highlight to all duplicates to be safe
                                dupMesh.material.emissive.setHex(0xffd700);
                                dupMesh.material.emissiveIntensity = 0.8;
                                dupMesh.scale.set(1.5, 1.5, 1.5);
                                dupMesh.material.needsUpdate = true;
                                console.warn(`  Applied duplicate highlight to: ${dupMesh.id}`);
                            }
                        });
                    }

                } else if (mesh.userData.type === 'file') {
                    mesh.material.emissive.setHex(0xffd700);
                    mesh.material.emissiveIntensity = 0.6;
                    mesh.material.needsUpdate = true;
                    document.getElementById('selectedNode').textContent = safeName(selectedNode.name);
                }

                console.log('=== selectNode completed ===');

                // Force immediate render
                renderer.render(scene, camera);

                // Also log what we can see in the camera's view
                setTimeout(() => {
                    console.log('🎥 Post-selection camera info:');
                    console.log('Camera position:', camera.position.x, camera.position.y, camera.position.z);
                    const direction = new THREE.Vector3();
                    camera.getWorldDirection(direction);
                    console.log('Camera direction:', direction.x, direction.y, direction.z);
                }, 100);
            }

            function openFile(symbol) {
                if (!symbol.filepath) {
                    console.error('No filepath available for symbol:', symbol);
                    return;
                }

                const requestData = {
                    filepath: symbol.filepath,
                    line: symbol.line || 1,
                    column: symbol.column || 1
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
                        console.log('File opened successfully:', symbol.filepath);
                    } else {
                        console.error('Failed to open file:', data.error);
                    }
                })
                .catch(error => {
                    console.error('Error opening file:', error);
                });
            }

            function resetView() {
                // Reset camera position to better angle
                sphericalCoords.theta = 0;
                sphericalCoords.phi = Math.PI / 4; // 45 degrees for better viewing
                sphericalCoords.radius = 80;
                updateCameraPosition();
                // If we're in single file mode, return to all files
                const showAllBtn = document.getElementById('showAllFilesBtn');
                if (showAllBtn) {
                    returnToAllFiles();
                }
            }

            function fitToView() {
                // Calculate bounding box of visible nodes
                const box = new THREE.Box3();
                nodeMeshes.forEach(mesh => {
                    box.expandByObject(mesh);
                });

                if (!box.isEmpty()) {
                    const size = box.getSize(new THREE.Vector3());
                    const maxDim = Math.max(size.x, size.y, size.z);
                    sphericalCoords.radius = Math.max(maxDim * 1.2, 30);
                    updateCameraPosition();
                }
            }

            function focusOnSelected() {
                if (!selectedNode) {
                    alert('Please select a symbol first!');
                    return;
                }

                const selectedMesh = nodeMeshes.find(m => m.userData.data === selectedNode);
                if (selectedMesh) {
                    focusOnNode(selectedMesh);
                }
            }

            function onWindowResize() {
                camera.aspect = window.innerWidth / window.innerHeight;
                camera.updateProjectionMatrix();
                renderer.setSize(window.innerWidth, window.innerHeight);
            }

            function animate() {
                requestAnimationFrame(animate);
                if (autoRotate) {
                    sphericalCoords.theta += 0.005;
                    updateCameraPosition();
                }

                renderer.render(scene, camera);
            }

            // Initialize when DOM is ready
            console.log('Script loaded, checking DOM ready state...');
            if (document.readyState === 'loading') {
                console.log('DOM is still loading, waiting for DOMContentLoaded...');
                document.addEventListener('DOMContentLoaded', () => {
                    console.log('DOM loaded, starting Three.js load...');
                    loadThreeJS();
                });
            } else {
                console.log('DOM is already loaded, starting Three.js load...');
                loadThreeJS();
            }
        </script>
    </body>
    </html>
    ]]

  return html
end

return M
