-- Gruvbox Dark (medium), a mesma paleta do kitty, alacritty, herdr e btop.
return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = { contrast = "" },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "gruvbox" } },
}
