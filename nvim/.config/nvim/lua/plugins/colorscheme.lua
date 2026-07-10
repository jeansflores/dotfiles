return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      variant = "moon", -- define a variante como moon
      dark_variant = "moon",
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      vim.cmd("colorscheme rose-pine-moon")
    end,
  },
  -- Configura o LazyVim para usar o tema
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-moon",
    },
  },
}
