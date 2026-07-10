-- [[ UI Plugins ]]
-- Visual enhancements and interface improvements.

return {
  -- noice: UI replacement for messages, cmdline, and popups
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      cmdline = { enabled = true },
      messages = { enabled = true },
      popupmenu = { enabled = true },
      notify = { enabled = true },
      lsp = {
        progress = { enabled = true },
        hover = { enabled = true },
        signature = { enabled = true },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
  },

  -- dashboard: startup screen
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function()
      local logo = {
        "    ╭━━━╮╱╱╱╭╮╱╱╱╱╱╱╱╭━━━╮╱╱╱╭╮",
        "    ┃╭━╮┃╱╱╱┃┃╱╱╱╱╱╱╱┃╭━╮┃╱╱╱┃┃",
        "    ┃┃╱╰╯╱╱╭┫┃╭━━┳━━┳━╯┃╱╰╯╭━━┫┃╭━━┳━━┳━╮",
        "    ┃┃╱╭┳━━┫┃┃┃╭╮┃╭╮┃╭╮┃╱╱╱┃╭╮┃┃┃╭╮┃╭╮┃╭╮╮",
        "    ┃╰━╯┣━━┃╰┫┃╰╯┃╭╮┃╰╯┃╱╱╱┃╰╯┃╰┫╭╮┃╰╯┃┃┃┃",
        "    ╰━━━╯╱╱╰━┻┻━╮┣╯┃┣━━╯╱╱╱╰━╮┣━┻╯╰┻━━┻╯╰╯",
        "    ╱╱╱╱╱╱╱╱╱╱╱╱╰━╯╰╯╱╱╱╱╱╱╱╱╰━╯",
        "                                          ",
        "    Windows Native Dev Stack Distro        ",
        "    Herdr • Neovim • Peri • Starship       ",
      }

      local opts = {
        hide = {
          statusline = false,
          tabline = false,
          winbar = false,
        },
        config = {
          header = logo,
          center = {
            { action = "Telescope find_files", desc = " Find file", icon = "📁 ", key = "f" },
            { action = "Telescope live_grep", desc = " Grep project", icon = "🔍 ", key = "g" },
            { action = "Telescope oldfiles", desc = " Recent files", icon = "🕒 ", key = "r" },
            { action = "Lazy", desc = " LazyVim", icon = "💤 ", key = "l" },
            { action = "qa", desc = " Quit", icon = "🚪 ", key = "q" },
          },
          footer = { "tzemed v1.0.0" },
        },
      }
      return opts
    end,
  },

  -- catppuccin: colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      term_colors = true,
      integrations = {
        telescope = true,
        gitsigns = true,
        noice = true,
        notify = true,
        dashboard = true,
        which_key = true,
        indent_blankline = { enabled = true },
        native_lsp = { enabled = true },
      },
    },
  },
}
