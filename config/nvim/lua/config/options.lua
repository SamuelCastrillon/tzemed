-- [[ Tzemed-specific Neovim Options ]]
-- Only overrides from LazyVim defaults are set here.

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Search
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cmdheight = 1
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Split behavior
opt.splitright = true
opt.splitbelow = true

-- Mouse
opt.mouse = "a"

-- Clipboard
opt.clipboard = "unnamedplus"

-- Undo / backup / swap
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- Timeouts
opt.timeoutlen = 300
opt.updatetime = 250
