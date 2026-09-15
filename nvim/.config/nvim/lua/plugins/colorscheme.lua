return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      -- Mesma variante do Ghostty/Waybar: Gruvbox Dark Hard
      contrast = "hard",
      terminal_colors = true,
      transparent_mode = false,
      bold = true,
      italic = {
        comments = true,
        emphasis = true,
        folds = true,
        operators = false,
        strings = false,
      },
    },
  },
  -- Configura o LazyVim para usar o tema
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
