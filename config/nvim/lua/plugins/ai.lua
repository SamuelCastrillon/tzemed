-- [[ AI Integration: Peri ]]
-- Integrates Peri as a floating terminal within Neovim.
-- Visual identity: Tzemed violet brand (violet-800 #5b21b6), dark bg (#110f18)

return {
  -- toggleterm: floating terminal support
  {
    "akinsho/toggleterm.nvim",
    cmd = { "TermExec", "ToggleTerm", "Peri" },
    keys = {
      {
        "<leader>ap",
        "<cmd>Peri<CR>",
        desc = " Toggle Peri agent",
      },
    },
    opts = {
      size = 20,
      open_mapping = nil, -- handled by custom command
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 0,
        highlights = {
          border = "TzemedTermBorder",
          background = "TzemedTermBg",
        },
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      -- Create Peri terminal command
      local Terminal = require("toggleterm.terminal").Terminal
      local peri_term = Terminal:new({
        cmd = "peri",
        direction = "float",
        hidden = true,
        on_open = function(term)
          vim.api.nvim_buf_set_keymap(
            term.bufnr, "t", "<Esc>",
            "<C-\\><C-n>", { noremap = true, silent = true }
          )

          -- Set the floating window title
          local winid = term.window
          if winid then
            vim.api.nvim_win_set_config(winid, {
              title = "   Peri  ",
              title_pos = "center",
            })
          end
        end,
        on_close = function()
          -- no-op
        end,
      })

      -- :Peri command — toggle Peri floating terminal
      vim.api.nvim_create_user_command("Peri", function()
        peri_term:toggle()
      end, { desc = "Toggle Peri AI agent in Tzemed floating terminal" })
    end,
  },
}
