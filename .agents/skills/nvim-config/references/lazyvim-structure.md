# LazyVim Directory Layout & Key Patterns

## Standard Directory Structure

```
~/.config/nvim/                    # XDG_CONFIG_HOME/nvim
├── init.lua                       # Entry point: bootstraps lazy.nvim → require("config.lazy")
├── lazyvim.json                   # Persisted state (extras enabled, news read)
└── lua/
    ├── config/
    │   ├── lazy.lua               # require("lazy").setup({...}) — bootstrap, specs, imports
    │   ├── options.lua            # vim.opt overrides (loaded BEFORE LazyVim)
    │   ├── keymaps.lua            # vim.keymap.set (loaded on VeryLazy)
    │   └── autocmds.lua           # vim.api.nvim_create_autocmd (loaded on VeryLazy)
    └── plugins/                   # Plugin specs (auto-discovered by lazy.nvim)
        ├── editor.lua
        ├── ui.lua
        ├── lsp.lua
        ├── ai.lua
        └── tzemed.lua
```

## Loading Order

1. **`init.lua`** — Neovim reads this single file on startup
2. **`lua/config/options.lua`** — Applied before LazyVim startup; user overrides win
3. **lazy.nvim Setup** (in `lazy.lua`):
   - `lazyvim.plugins` (core LazyVim specs)
   - Extras from `lazyvim.json`
   - User plugin specs (Tzemed uses explicit `{ import = "plugins.<name>" }` entries)
4. **`VeryLazy` Event** (after all plugins loaded):
   - `lua/config/keymaps.lua`
   - `lua/config/autocmds.lua`

## Tzemed-Specific Patterns

| Pattern | Tzemed Approach |
|---------|----------------|
| Plugin imports | **Explicit** — each plugin file listed in `lazy.lua` `spec` table, NOT auto-discovery |
| Theme | `lua/config/theme.lua` with custom `nvim_set_hl` calls, loaded after colorscheme in `lazy.lua` |
| Colorscheme | TokyoNight (`install.colorscheme = { "tokyonight" }`) with Tzemed violet-800 (`#5b21b6`) overrides |
| LSP | Mason auto-installs via `lsp.lua` plugin spec |
| Peri integration | `ai.lua` plugin — toggleterm floating terminal, `<leader>ap` keymap in `keymaps.lua` |

## Key Neovim v0.12 APIs

| API | Purpose |
|-----|---------|
| `vim.opt` | Set Vim options from Lua |
| `vim.keymap.set(mode, lhs, rhs, opts)` | Create keymaps |
| `vim.api.nvim_create_autocmd(event, opts)` | Create autocommands |
| `vim.api.nvim_create_augroup(name, opts)` | Create autocommand groups |
| `vim.api.nvim_set_hl(ns, name, val)` | Set highlight groups |
| `vim.lsp.config(name, opts)` | Configure LSP servers (0.11+) |
| `vim.uv` | File system and process operations (replaces `vim.loop`) |
| `vim.fn.stdpath("config")` | Config directory path (respects `$XDG_CONFIG_HOME`) |

## Common Plugin Spec Keys

```lua
{
  "author/repo",                    -- Required: plugin source
  lazy = false,                     -- Load on startup (default)
  event = "BufRead",                -- Lazy-load on event
  cmd = { "Telescope" },            -- Lazy-load on command
  keys = { { "<leader>ff", desc = "Find files" } },  -- Lazy-load on keymap
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = { ... },                   -- Passed to plugin's config() as default opts
  opts = function(_, opts)          -- Merge into LazyVim defaults
    opts.key = value
    return opts
  end,
  config = function(_, opts) end,   -- Custom setup (only if opts is not enough)
  enabled = false,                  -- Disable a LazyVim default plugin
  init = function() end,            -- Run BEFORE plugin loads
}
```

## Windows-Specific Notes

- `stdpath("config")` = `%USERPROFILE%\AppData\Local\nvim` if `$XDG_CONFIG_HOME` is not set
- Tzemed sets `$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"` in `$PROFILE`
- With that set: `stdpath("config")` = `C:\Users\<user>\.config\nvim`
- Scoop installs Neovim v0.12.4 at the bucket-managed path
