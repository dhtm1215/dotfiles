return {
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>-",
        "<cmd>Yazi<cr>",
        mode = { "n", "v" },
        desc = "Open Yazi",
      },
      {
        "<leader>cw",
        "<cmd>Yazi cwd<cr>",
        desc = "Open Yazi cwd",
      },
      {
        "<c-up>",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume Yazi",
      },
    },
    opts = {
      open_for_directories = false,
      floating_window_scaling_factor = 0.9,
      yazi_floating_window_border = "rounded",
    },
  },
}
