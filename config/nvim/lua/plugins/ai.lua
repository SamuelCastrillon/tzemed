-- [[ AI Integration: Peri ]]
-- Integrates Peri as a floating terminal within Neovim.

return {
  -- toggleterm: floating terminal support
  {
    "akinsho/toggleterm.nvim",
    cmd = { "TermExec", "ToggleTerm", "Peri" },
    keys = {
      { "<leader>ap", "<cmd>Peri<CR>", desc = "Toggle Peri AI agent" },
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
        winblend = 3,
        highlights = {
          border = "Normal",
          background = "Normal",
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
          vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
        end,
        on_close = function()
          vim.cmd("echo 'Peri session closed'")
        end,
      })

      -- :Peri command — toggle Peri floating terminal
      vim.api.nvim_create_user_command("Peri", function()
        peri_term:toggle()
      end, { desc = "Toggle Peri AI agent in floating terminal" })
    end,
  },
}
