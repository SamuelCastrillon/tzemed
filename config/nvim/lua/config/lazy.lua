-- [[ LazyVim Bootstrap ]]
-- Load LazyVim and all plugins from lua/plugins/
-- Theme: TokyoNight with Tzemed palette (violet-800 #5b21b6 brand)

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  return -- bootstrap handles this in init.lua
end

-- Import options, keymaps, autocmds, and theme
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.theme").setup()

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
    colorscheme = { "tokyonight" },
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
  ui = {
    -- Tzemed header for the :Lazy plugin manager UI
    header = {
      "        ████████╗███████╗███████╗███╗   ███╗███████╗██████╗ ",
      "        ╚══██╔══╝╚══███╔╝╚══███╔╝████╗ ████║██╔════╝██╔══██╗",
      "           ██║     ███╔╝   ███╔╝ ██╔████╔██║█████╗  ██║  ██║",
      "           ██║    ███╔╝   ███╔╝  ██║╚██╔╝██║██╔══╝  ██║  ██║",
      "           ██║   ███████╗███████╗██║ ╚═╝ ██║███████╗██████╔╝",
      "           ╚═╝   ╚══════╝╚══════╝╚═╝     ╚═╝╚══════╝╚═════╝ ",
      "",
      "        Windows Native Dev Stack Distro",
      "        Herdr • Neovim • Peri • Starship",
    },
  },
})
