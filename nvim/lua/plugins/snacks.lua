return {
  {
    "snacks.nvim",
    optional = true,
    opts = function(_, opts)
      opts.image = opts.image or {}
      opts.image.enabled = false
      opts.image.doc = vim.tbl_deep_extend("force", opts.image.doc or {}, {
        enabled = false,
        inline = false,
        float = false,
      })
    end,
  },
}
