# LSP Call Chain Visualizer

A Neovim plugin that provides interactive 3D visualization of LSP call hierarchies using Three.js.

<div style="text-align:center;">
<img src="https://private-user-images.githubusercontent.com/41671631/458843041-7a895c63-7ff4-4877-ad38-9563f6347591.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTA4NTAyOTUsIm5iZiI6MTc1MDg0OTk5NSwicGF0aCI6Ii80MTY3MTYzMS80NTg4NDMwNDEtN2E4OTVjNjMtN2ZmNC00ODc3LWFkMzgtOTU2M2Y2MzQ3NTkxLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA2MjUlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwNjI1VDExMTMxNVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWVlMmM1YWE5MmRhM2U1NWQwYjE5Yzg4YTRiY2Q3NTBhNjUwYzdhY2VjMGQyOTA2ODBiMzAxMmRlNjUxNjcxM2YmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.Ip1Qb7ABO2Lm9V5v5yZZ5W3cg7bbfP58YOyWEiufu-E" width="600" height="400">
</div>

## Features

- 🎯 **Interactive 3D Visualization** - Navigate call hierarchies in an intuitive 3D space
- 🔍 **Precise Navigation** - Click nodes to open files at exact line:column positions  
- 📍 **Location Display** - Shows `filename:line:column` for each function
- 🎨 **Visual Feedback** - Different shapes and colors for different node types
- 📝 **Visit Tracking** - Visited nodes turn gold to track exploration progress
- ⚡ **Real-time Physics** - Dynamic force-directed layout with adjustable parameters

## Usage

1. Place cursor on a function
2. Use one of the commands:
   - `VisualizerIncoming` - Show functions that call this one
   - `VisualizerOutgoing` - Show functions this one call
   - `VisualizerFull`     - Show both incoming and outgoing calls

3. In the 3D visualization:
   - **Click nodes** to open files in Neovim
   - **Drag** to rotate camera
   - **Scroll** to zoom
   - **Toggle physics** to pause/resume animation
   - **Clear visited** to reset visit tracking


## License

MIT
