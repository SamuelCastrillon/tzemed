-- [[ LazyVim Bootstrap ]]
-- Load LazyVim and all plugins from lua/plugins/

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  return -- bootstrap handles this in init.lua
end

-- Import options, keymaps, and autocmds
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Setup lazy.nvim with LazyVim
require("lazy").setup({
  spec = {
    -- Import LazyVim
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Import Tzemed-specific plugins
    { import = "plugins.editor" },
    { import = "plugins.ui" },
    { import = "plugins.lsp" },
    { import = "plugins.ai" },
    { import = "plugins.tzemed" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = {
    colorscheme = { "catppuccin" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    cache = {
      enabled = true,
    },
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
