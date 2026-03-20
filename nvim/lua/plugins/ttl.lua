return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if type(opts.ensure_installed) == "table" then
        if not vim.tbl_contains(opts.ensure_installed, "turtle") then
          table.insert(opts.ensure_installed, "turtle")
        end
      end
    end,
  },
}
