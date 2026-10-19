-- Rosé Pine Moon, a mesma paleta do kitty, alacritty, herdr e btop.
return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    opts = { variant = "moon", dark_variant = "moon" },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "rose-pine-moon" } },
}
