-- [[ Tzemed Neovim Keymaps ]]
-- LazyVim default keymaps are preserved. Only Tzemed-specific additions go here.

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Better navigation between splits
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Resize splits with arrows
map("n", "<C-Up>", "<cmd>resize +2<CR>", opts)
map("n", "<C-Down>", "<cmd>resize -2<CR>", opts)
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opts)
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)

-- Better indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Quick escape with jk
map("i", "jk", "<Esc>", opts)

-- Clear search highlights
map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)

-- Save file
map("n", "<C-s>", "<cmd>w<CR>", opts)

-- Quit
map("n", "<C-q>", "<cmd>q<CR>", opts)

-- Telescope keymaps (LazyVim uses <leader>ff, <leader>fg, etc.)
-- Peri integration: <leader>ap opens Peri floating terminal
map("n", "<leader>ap", "<cmd>Peri<CR>", { desc = "Toggle Peri AI agent" })
