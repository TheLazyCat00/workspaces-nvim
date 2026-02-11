# workspaces.nvim

A simple and persistent file pinning plugin for Neovim. `workspaces.nvim` allows you to pin files to specific keys within a project workspace, giving you quick access to your most important files. It includes a floating UI that displays your pinned files.

## Features

- **Project-Specific Persistence**: Pinned files are saved per project (based on your current working directory).
- **Floating UI**: A discreet floating window shows your pinned files and their corresponding keys.
- **Visual Indicators**: Highlights the current file and shortcut keys.
- **Customizable**: Configure keys, colors, and UI position.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "TheLazyCat00/workspaces-nvim",
	lazy = false, -- workspaces-nvim handles lazy loading by itself
	opts = {}
}
```

## Configuration

You can customize the plugin by passing a table to the `setup` function. Here are the default values:

```lua
{
    -- Keys to use for pinning (must be a string)
    keys = "1234567890",
    
    -- Prefix for switching to a pinned file
    -- Example: <leader>1 switches to the file pinned to '1'
    selectLeaderKey = "<leader>",
    
    -- Prefix for pinning the current file
    -- Example: <leader>h1 pins the current file to '1'
    pinLeaderKey = "<leader>h",
    
    -- Key binding to clear all pins in the current workspace
    clearKey = "<leader>hd",
    
    -- Highlight colors
    colors = {
        shortcut = "#EA572A",   -- Color for the key shortcut in the UI
        currentFile = "#06ADDB", -- Color for the currently active file in the UI
    },
    
    -- UI Window offset
    offset = {
        x = 0,
        y = 0,
    }
}
```

## Usage

| Action | Default Binding | Description |
|--------|-----------------|-------------|
| **Pin File** | `<leader>h` + `[key]` | Pin the current buffer to the specified key (e.g., `<leader>h1` pins to `1`). |
| **Switch to File** | `<leader>` + `[key]` | Switch to the buffer pinned to the specified key (e.g., `<leader>1` switches to file `1`). |
| **Clear Workspace** | `<leader>hd` | Remove all pinned files for the current project. |

The UI will automatically update as you pin files or switch buffers.

## Data Storage

Workspace data is stored in `stdpath("data") .. "/workspaces-nvim/workspaces.json"`.
