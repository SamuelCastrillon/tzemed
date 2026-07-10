-- [[ UI Plugins ]]
-- Visual enhancements and interface improvements.
-- Theme: TokyoNight with Tzemed palette (violet-800 #5b21b6 brand)

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

  -- dashboard: Tzemed startup screen
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
            { action = "Telescope find_files", desc = " Find file",     icon = " ", key = "f" },
            { action = "Telescope live_grep",  desc = " Grep project",  icon = " ", key = "g" },
            { action = "Telescope oldfiles",   desc = " Recent files",  icon = " ", key = "r" },
            { action = "Peri",                 desc = " Peri agent",    icon = " ", key = "a" },
            { action = "Lazy",                 desc = " Plugins",       icon = " ", key = "l" },
            { action = "qa",                   desc = " Quit",          icon = " ", key = "q" },
          },
          footer = { "tzemed v1.0.1" },
        },
      }
      return opts
    end,
  },

  -- tokyonight: colorscheme with Tzemed palette
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments  = { italic = true, fg = "#565f89" },
        keywords  = { fg = "#bb9af7" },
        functions = { fg = "#7aa2f7" },
        variables = { fg = "#c0caf5" },
        constants = { fg = "#ff9e64" },
        numbers   = { fg = "#ff9e64" },
        operators = { fg = "#bb9af7" },
        type      = { fg = "#9ece6a" },
        strings   = { fg = "#9ece6a" },
        parameters = { fg = "#c0caf5" },
        property  = { fg = "#7dcfff" },
        builtin   = { fg = "#bb9af7" },
      },
      on_colors = function(colors)
        -- Tzemed brand palette (Tailwind violet-800 / stone-950)
        colors.hint    = "#7c3aed"
        colors.error   = "#ff5353"
        colors.warning = "#e0af68"
        colors.info    = "#7dcfff"

        -- Tzemed violet brand
        colors.purple   = "#7c3aed"
        colors.blue     = "#7aa2f7"
        colors.cyan     = "#7dcfff"
        colors.green    = "#9ece6a"
        colors.yellow   = "#e0af68"
        colors.orange   = "#ff9e64"
        colors.red      = "#f7768e"
        colors.fg       = "#c0caf5"
        colors.fg_dim   = "#565f89"

        -- Background override
        colors.bg       = "#0c0c0c"
        colors.bg_dark  = "#0c0c0c"
        colors.bg_float = "#110f18"
        colors.bg_popup = "#110f18"
        colors.bg_sidebar = "#0c0c0c"
        colors.bg_statusline = "#110f18"
      end,
      on_highlights = function(hl, c)
        -- Tzemed highlight overrides
        hl.Visual = { bg = "#292e42", fg = "#c0caf5" }
        hl.CursorLine = { bg = "#1a1b26", fg = "#c0caf5" }

        -- Search with Tzemed brand (violet-800)
        hl.Search = { bg = "#5b21b6", fg = "#1a1b26" }
        hl.IncSearch = { bg = "#5b21b6", fg = "#1a1b26" }
        hl.MatchParen = { fg = "#7c3aed", bold = true }

        -- Line numbers
        hl.LineNr = { fg = "#565f89" }
        hl.CursorLineNr = { fg = "#7c3aed", bold = true }

        -- Popup menu
        hl.Pmenu = { bg = "#1a1b26", fg = "#c0caf5" }
        hl.PmenuSel = { bg = "#5b21b6", fg = "#1a1b26" }
        hl.PmenuSbar = { bg = "#292e42" }
        hl.PmenuThumb = { bg = "#565f89" }
      end,
    },
  },
}
