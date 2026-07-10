# Tzemed

> **צמד** — *"yunta/team"* en hebreo.
> Una distro curada, instalable y nativa de Windows para desarrollo con IA.

**Stack**: Herdr + Neovim (LazyVim) + Peri + Starship + Gentle-ai SDD

---

## Quick Start

### Prerequisites

- **Windows 10 1809** (build 17763) or later
- **Scoop** package manager ([install](https://scoop.sh))

### Install

```powershell
# Add the Tzemed bucket
scoop bucket add tzemed https://github.com/gentleman-programming/tzemed

# Install Tzemed and all dependencies
scoop install tzemed
```

### Initialize

```powershell
# Set up the full dev stack
tzemed
```

### Start Coding

```powershell
# Open Herdr with the Tzemed 3-pane layout
herdr
```

---

## What You Get

| Tool | Purpose |
|------|---------|
| **Herdr** | Terminal multiplexor with agent-aware workspaces |
| **Neovim** | Editor with LazyVim, LSP, completion, Git integration |
| **Peri** | Multi-LLM AI agent (≈13MB, ≈50MB RAM) |
| **Starship** | Fast cross-platform prompt |
| **SDD** | Spec-Driven Development workflow for AI-assisted coding |

### Configurations

All configurations are deployed automatically:

- **Neovim** → `~/.config/nvim/` — LazyVim-based with LSP (lua_ls, ts_ls, pyright), Telescope, Git integration, and Peri floating terminal (`:Peri`)
- **Herdr** → `~/.config/herdr/config.toml` — 3-pane layout (nvim / terminal / peri)
- **Peri** → `~/.peri/settings.json` — AI agent config (no model shipped, first-launch wizard)
- **Starship** → `~/.config/starship.toml` — Git status, runtime versions, command duration

### Keymaps

See [docs/nvim-keymaps.md](docs/nvim-keymaps.md) for the full reference.

---

## Architecture

```
~/.config/
├── nvim/              # Neovim (LazyVim)
│   ├── init.lua
│   └── lua/
│       ├── config/    # options, keymaps, autocmds, lazy
│       └── plugins/   # editor, ui, lsp, ai, tzemed
├── herdr/
│   └── config.toml    # 3-pane layout
├── starship.toml      # Git, runtimes, duration
~/.peri/
└── settings.json      # Peri config (no model, editor: nvim)
```

See [docs/architecture.md](docs/architecture.md) for the full architecture documentation.

---

## Project Structure

```
tzemed/
├── scoop-bucket/      # Scoop manifest
├── scripts/           # Installer and entry point
├── config/            # All tool configurations
│   ├── nvim/
│   ├── herdr/
│   ├── peri/
│   └── starship.toml
├── tests/             # Unit and E2E tests
│   ├── unit/
│   └── e2e/
├── docs/              # Documentation
└── AGENTS.md          # AI agent context
```

---

## Development

```powershell
# Run unit tests
Invoke-Pester tests/unit/

# Run E2E tests
pwsh -File tests/e2e/install.E2E.ps1

# Check nvim health
pwsh -File tests/nvim-health.ps1
```

---

## License

MIT — see [LICENSE](LICENSE).
