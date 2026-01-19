-- Catppuccin (Mocha) theme as default
--
-- Default behavior: use Catppuccin (flavour defaults to mocha).
-- Override:
--   NVIM_THEME=tokyonight nvim
-- Optional:
--   NVIM_CATPPUCCIN_FLAVOUR=mocha|macchiato|frappe|latte
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = function()
      local flavour = (vim.env.NVIM_CATPPUCCIN_FLAVOUR and vim.env.NVIM_CATPPUCCIN_FLAVOUR ~= "") and vim.env.NVIM_CATPPUCCIN_FLAVOUR
        or "mocha"

      return {
        flavour = flavour,
        integrations = {
          cmp = true,
          gitsigns = true,
          native_lsp = { enabled = true },
          treesitter = true,
          telescope = true,
          which_key = true,
        },
      }
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      -- Default to Catppuccin, but allow env var overrides.
      local theme = vim.env.NVIM_THEME
      if not theme or theme == "" then
        opts.colorscheme = "catppuccin"
        return opts
      end

      if theme == "catppuccin" or theme == "catppuccin-mocha" or theme == "mocha" then
        opts.colorscheme = "catppuccin"
      else
        opts.colorscheme = theme
      end

      return opts
    end,
  },
}
