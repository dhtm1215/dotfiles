local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Markdown 문법 conceal 때문에 본문이 숨겨지는 문제 방지
autocmd("FileType", {
  group = augroup("markdown_no_conceal", { clear = true }),
  pattern = { "markdown", "md" },
  callback = function()
    vim.opt_local.conceallevel = 0
    vim.opt_local.concealcursor = ""
  end,
})
