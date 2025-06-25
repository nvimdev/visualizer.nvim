# LSP Call Chain Visualizer

A Neovim plugin that provides interactive 3D visualization of LSP call hierarchies using Three.js.

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
