return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      -- Mesma variante do Ghostty/Waybar: TokyoNight Night
      style = "night",
      light_style = "day",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
        sidebars = "dark", -- explorer, trouble, etc.
        floats = "dark", -- janelas flutuantes (picker, lazy, mason)
      },
    },
  },
  -- Configura o LazyVim para usar o tema
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
}
