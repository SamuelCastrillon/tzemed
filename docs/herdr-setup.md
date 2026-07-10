# Herdr Setup

## Overview

[Herdr](https://github.com) is a Rust-native terminal multiplexor with agent-aware workspaces. Tzemed configures Herdr with a 3-pane layout for development.

## Default Layout: `tzemed`

```
┌──────────────────────┬────────────────┐
│                      │   Terminal     │
│       nvim           │   (pwsh)       │
│                      │                │
│       (60%)          ├────────────────┤
│                      │   Peri         │
│                      │   (AI Agent)   │
└──────────────────────┴────────────────┘
```

- **Left (60%)**: Neovim editor
- **Right-top (70%)**: PowerShell terminal
- **Right-bottom (30%)**: Peri AI agent

## Configuration File

**Path**: `~/.config/herdr/config.toml`

```toml
[general]
default_layout = "tzemed"
editor = "nvim"

[layouts.tzemed]
direction = "horizontal"

[[layouts.tzemed.panes]]
command = "nvim"
size = "60%"
border = true

[[layouts.tzemed.panes]]
direction = "vertical"
size = "40%"

[[layouts.tzemed.panes.panes]]
command = "pwsh"
size = "70%"

[[layouts.tzemed.panes.panes]]
command = "peri"
size = "30%"
```

## Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+R` | Reload Herdr config |
| `Alt+L` | Focus next pane |
| `Alt+H` | Focus previous pane |
| `Ctrl+W` | Close current pane |
| `Ctrl+Enter` | Toggle fullscreen for current pane |

## First Launch

1. After installing Tzemed, run `herdr` in PowerShell
2. Herdr reads `~/.config/herdr/config.toml` and opens the `tzemed` layout
3. Nvim starts automatically in the left pane
4. Use `Alt+L` / `Alt+H` to switch between panes
5. Run `:Peri` inside nvim to open the Peri AI agent as a floating terminal

## Troubleshooting

### Herdr doesn't start
- Verify `herdr --version` works
- Reinstall: `scoop install herdr`
- Check config file at `~/.config/herdr/config.toml`

### Layout doesn't match
- Ensure the config file is valid TOML
- Reload config: `Ctrl+Shift+R` inside Herdr
- Reset to defaults by re-running `tzemed`

### Herdr not found after install
- Scoop should add shims to PATH automatically
- Run `scoop reset herdr` to refresh shims
