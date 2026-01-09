return {
  "yetone/avante.nvim",
  config = function()
    require("avante").setup({
      provider = "gemini",
      gemini = {
        api_key = os.getenv("GEMINI_API_KEY"),
        model = "gemini-2.5-flash-lite",
      },
    })
  end,
}
