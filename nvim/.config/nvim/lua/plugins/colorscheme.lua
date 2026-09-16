return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    -- As opções do gruvbox-material são variáveis globais e precisam existir
    -- antes de o tema carregar — daí `init`, e não `config`.
    init = function()
      -- Mesma variante do Ghostty/Waybar: Material, fundo hard
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_enable_bold = 1
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_transparent_background = 0
    end,
  },
  -- Configura o LazyVim para usar o tema
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox-material",
    },
  },
}
