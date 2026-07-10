-- [[ Tzemed Autocommands ]]

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- General settings group
local tzemed_group = augroup("Tzemed", { clear = true })

-- Highlight on yank
autocmd("TextYankPost", {
  group = tzemed_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Resize splits on window resize
autocmd("VimResized", {
  group = tzemed_group,
  pattern = "*",
  command = "tabdo wincmd =",
})

-- Return to last edit position
autocmd("BufReadPost", {
  group = tzemed_group,
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close some filetypes with <q>
autocmd("FileType", {
  group = tzemed_group,
  pattern = {
    "qf", "help", "man", "lspinfo", "spectre_panel", "PlenaryTestPopup",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})
