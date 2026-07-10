---
name: nvim-config
description: "Trigger: nvim, neovim, init.lua, lazyvim, options, keymaps, plugins. Guide for Neovim v0.12.4 + LazyVim configuration structure and patterns."
license: Apache-2.0
metadata:
  author: "SamuelCastrillon"
  version: "1.0"
---

## Activation Contract

Load this skill when editing any file under `~/.config/nvim/` (resolved via `$env:XDG_CONFIG_HOME`), or when the user asks about Neovim options, keymaps, autocommands, LazyVim plugin specs, or Tzemed-specific overrides. Also activate when adding/removing/changing Neovim plugins.

## Hard Rules

1. **`init.lua` is the single entry point.** Neovim reads only this file on startup. It bootstraps `lazy.nvim` and calls `require("config.lazy")`. Do NOT create `init.vim` alongside it — Neovim ignores `init.vim` when `init.lua` exists.
2. **`options.lua` loads BEFORE LazyVim startup.** Vim options set here can affect plugin behavior. Options set AFTER LazyVim starts (in `lazy.lua` or plugin specs) may be overwritten by LazyVim defaults.
3. **Keymaps and autocmds load on `VeryLazy` event.** Files `lua/config/keymaps.lua` and `lua/config/autocmds.lua` are loaded automatically by LazyVim after all plugins. Do NOT call `require` on them manually unless you need immediate loading.
4. **Plugin specs MUST return a table.** Every file under `lua/plugins/` must `return { ... }` with lazy.nvim spec entries. A file that returns an empty table `{}` is valid for disabling.
5. **Tzemed uses explicit plugin imports in `lazy.lua`**, not auto-discovery. Every plugin file must be listed in the `spec` table as `{ import = "plugins.<name>" }`. Adding a `.lua` file to `lua/plugins/` without adding its import has no effect.
6. **`$env:XDG_CONFIG_HOME` must be set to `$env:USERPROFILE\.config`.** Without it, `stdpath("config")` points elsewhere and Neovim won't find the Tzemed config.
7. **Never use `vim.cmd` for settings that have Lua APIs.** Use `vim.opt`, `vim.keymap.set`, `vim.api.nvim_create_autocmd`, and `vim.api.nvim_set_hl` instead.
8. **Theme overrides in `theme.lua` run AFTER colorscheme load.** Custom `nvim_set_hl` calls must happen after the colorscheme is applied, or they get overwritten.

## Decision Gates

| Need | Action |
|------|--------|
| Add a new plugin | Create `lua/plugins/<name>.lua`, add `{ import = "plugins.<name>" }` to the `spec` table in `lazy.lua` |
| Override a LazyVim default option | Edit `lua/config/options.lua` using `vim.opt` |
| Add/override a keymap | Edit `lua/config/keymaps.lua` using `vim.keymap.set` |
| Add an autocommand | Edit `lua/config/autocmds.lua` using `vim.api.nvim_create_autocmd` + `nvim_create_augroup` |
| Custom highlight/color groups | Edit `lua/config/theme.lua` using `vim.api.nvim_set_hl` |
| Override a LazyVim plugin config | Edit the corresponding file in `lua/plugins/` — use the same plugin key as LazyVim's spec |
| Disable a LazyVim plugin | Add `{ "<plugin-name>", enabled = false }` to any file under `lua/plugins/` |
| Auto-install a Mason tool | Add the tool name to the `ensure_installed` list in the Mason plugin spec (`lua/plugins/lsp.lua`) |
| Change LazyVim extras | Edit the `spec` table in `lua/config/lazy.lua` to add/remove `{ import = "lazyvim.plugins.extras.lang.<lang>" }` |

## Execution Steps

1. **Identify the layer**: entry point (`init.lua`), bootstrap (`config/lazy.lua`), options (`config/options.lua`), keymaps (`config/keymaps.lua`), autocmds (`config/autocmds.lua`), theme (`config/theme.lua`), or a plugin spec (`plugins/<name>.lua`).
2. **For options**: use `vim.opt.<name> = <value>` in `options.lua`. Do NOT wrap in `vim.cmd("set ...")`.
3. **For keymaps**: use `vim.keymap.set(mode, lhs, rhs, opts)` in `keymaps.lua`. LazyVim default leader is `<Space>`.
4. **For autocmds**: create a named augroup via `vim.api.nvim_create_augroup("Name", { clear = true })`, then add autocmds with `vim.api.nvim_create_autocmd`.
5. **For plugin specs**: return a table with lazy.nvim entries. Support `keys`, `cmd`, `event`, `opts`, `dependencies`, `config`, and `enabled` keys. Use `opts = function(_, opts)` to merge into LazyVim defaults. Use `opts = function() return { ... }` to override entirely.
6. **Verify**: run `nvim --headless "+Lazy! sync" +qa` or check `:checkhealth` for errors. Run `:Lazy` to inspect loaded plugins.

## Output Contract

Return the exact code change (diff or snippet), the file path relative to `~/.config/nvim/`, and confirm the change follows the loading order rules. Reference `references/lazyvim-structure.md` for directory layout questions.

## References

- `references/lazyvim-structure.md` — LazyVim directory layout, loading order, and key patterns
- `~/.config/nvim/init.lua` — Tzemed entry point
- `~/.config/nvim/lua/config/lazy.lua` — Tzemed lazy.nvim bootstrap with explicit imports
- `~/.config/nvim/lua/config/options.lua` — Tzemed option overrides
- `~/.config/nvim/lua/config/keymaps.lua` — Tzemed custom keymaps
- `~/.config/nvim/lua/config/autocmds.lua` — Tzemed autocommands
- `~/.config/nvim/lua/config/theme.lua` — Tzemed highlight groups
