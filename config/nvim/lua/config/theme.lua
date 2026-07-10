-- [[ Tzemed Theme ]]
-- Custom highlight groups for Tzemed visual identity.
-- Palette: violet-800 #5b21b6 (brand), stone-950 #0c0c0c (bg), violet-600 #7c3aed (accent)
-- Tailwind-inspired dark theme. Applied after colorscheme is loaded.

local M = {}

function M.setup()
  local hl = vim.api.nvim_set_hl

  -- Tzemed brand highlight groups (used by dashboard, plugins, etc.)
  hl(0, "TzemedViolet",     { fg = "#5b21b6", default = true })
  hl(0, "TzemedVioletBold", { fg = "#5b21b6", bold = true, default = true })
  hl(0, "TzemedAccent",     { fg = "#7c3aed", default = true })
  hl(0, "TzemedAccentBold", { fg = "#7c3aed", bold = true, default = true })
  hl(0, "TzemedBgAlt",      { bg = "#110f18", default = true })
  hl(0, "TzemedBg",         { bg = "#0c0c0c", default = true })
  hl(0, "TzemedDim",        { fg = "#565f89", default = true })

  -- Which-key: override colors
  hl(0, "WhichKey",          { fg = "#7c3aed", default = true })
  hl(0, "WhichKeyGroup",     { fg = "#7dcfff", default = true })
  hl(0, "WhichKeyDesc",      { fg = "#c0caf5", default = true })
  hl(0, "WhichKeyFloat",     { bg = "#1a1b26", default = true })

  -- Telescope: use Tzemed accent for selection
  hl(0, "TelescopeSelection",      { bg = "#292e42", fg = "#7c3aed", default = true })
  hl(0, "TelescopeSelectionCaret", { fg = "#7c3aed", default = true })
  hl(0, "TelescopeBorder",         { fg = "#292e42", default = true })
  hl(0, "TelescopeNormal",         { bg = "NONE",    fg = "#c0caf5", default = true })

  -- Dashboard: Tzemed header styling
  hl(0, "DashboardHeader", { fg = "#5b21b6", default = true })
  hl(0, "DashboardIcon",   { fg = "#7c3aed", default = true })
  hl(0, "DashboardDesc",   { fg = "#c0caf5", default = true })
  hl(0, "DashboardKey",    { fg = "#7dcfff", default = true })

  -- ToggleTerm / Peri: Tzemed-themed floating terminal
  hl(0, "TzemedTermBorder",   { fg = "#5b21b6", default = true })
  hl(0, "TzemedTermBg",       { bg = "#110f18", default = true })
  hl(0, "TzemedTermTitle",    { fg = "#5b21b6", bold = true, default = true })
end

return M
