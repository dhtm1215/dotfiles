-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Theme toggles (opt-in; doesn't change your default theme)
vim.keymap.set("n", "<leader>uC", function()
  vim.cmd.colorscheme("catppuccin")
end, { desc = "Colorscheme: Catppuccin" })

vim.keymap.set("n", "<leader>uD", function()
  vim.cmd.colorscheme("default")
end, { desc = "Colorscheme: Default" })
