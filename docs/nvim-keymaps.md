# Neovim Keymaps

## General

| Key | Mode | Action |
|-----|------|--------|
| `<Esc>` | Normal | Clear search highlights (`:nohlsearch`) |
| `jk` | Insert | Escape to Normal mode |
| `<C-s>` | Normal, Insert | Save file |
| `<C-q>` | Normal | Quit current window |

## Window Navigation

| Key | Mode | Action |
|-----|------|--------|
| `<C-h>` | Normal | Move to left split |
| `<C-j>` | Normal | Move to split below |
| `<C-k>` | Normal | Move to split above |
| `<C-l>` | Normal | Move to right split |

## Split Resize

| Key | Mode | Action |
|-----|------|--------|
| `<C-Up>` | Normal | Increase height by 2 |
| `<C-Down>` | Normal | Decrease height by 2 |
| `<C-Left>` | Normal | Decrease width by 2 |
| `<C-Right>` | Normal | Increase width by 2 |

## Visual Mode

| Key | Mode | Action |
|-----|------|--------|
| `<` | Visual | Indent left, keep selection |
| `>` | Visual | Indent right, keep selection |
| `J` | Visual | Move selected lines down |
| `K` | Visual | Move selected lines up |

## LSP Keymaps

| Key | Mode | Action |
|-----|------|--------|
| `gd` | Normal | Go to definition |
| `gD` | Normal | Go to declaration |
| `K` | Normal | Hover documentation |
| `gi` | Normal | Go to implementation |
| `gr` | Normal | Find references |
| `g<C-k>` | Normal | Signature help |
| `<leader>D` | Normal | Go to type definition |
| `<leader>rn` | Normal | Rename symbol |
| `<leader>ca` | Normal | Code action |
| `<leader>wa` | Normal | Add workspace folder |
| `<leader>wr` | Normal | Remove workspace folder |
| `<leader>wl` | Normal | List workspace folders |
| `<leader>e` | Normal | Show diagnostics |
| `[d` | Normal | Previous diagnostic |
| `]d` | Normal | Next diagnostic |
| `<leader>q` | Normal | Quickfix list from diagnostics |

## Telescope

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ff` | Normal | Find files |
| `<leader>fg` | Normal | Live grep |
| `<leader>fb` | Normal | Find buffers |
| `<leader>fh` | Normal | Help tags |

## Git (vim-fugitive)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gs` | Normal | Git status |
| `<leader>gd` | Normal | Git diff |
| `<leader>gb` | Normal | Git blame |
| `<leader>gl` | Normal | Git log |

## Peri AI Integration

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ap` | Normal | Toggle Peri floating terminal |
| `:Peri` | Command | Toggle Peri floating terminal |

## Which-Key

| Key | Mode | Action |
|-----|------|--------|
| `<leader>` | Normal | WhichKey popup |

## Notes

- LazyVim provides additional default keymaps. See [LazyVim Keymaps](https://www.lazyvim.org/keymaps) for the full list.
- Tzemed only overrides or adds keymaps that differ from LazyVim defaults.
- All keymaps are defined in `~/.config/nvim/lua/config/keymaps.lua`.
