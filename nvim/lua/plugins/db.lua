-- lua/plugins/db.lua
return {
  {
    "tpope/vim-dadbod",
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      "tpope/vim-dadbod",
    },
    config = function()
      -- DBUI 열기 단축키: <leader>db
      vim.keymap.set("n", "<leader>db", ":DBUI<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "kristijanhusak/vim-dadbod-completion",
    ft = { "sql", "mysql", "plsql" },
  },
}
