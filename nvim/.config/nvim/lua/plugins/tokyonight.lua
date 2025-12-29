return {
  "folke/tokyonight.nvim",
  lazy = false,
  opts = {
    style = "moon",
    transparent = true,
    terminal_colors = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
    on_highlights = function(hl)
      hl.NormalFloat = { bg = "none" }
      hl.FloatBorder = { bg = "none" }
      hl.TelescopeNormal = { bg = "none" }
      hl.TelescopeBorder = { bg = "none" }
      hl.NeoTreeNormal = { bg = "none" }
      hl.NeoTreeNormalNC = { bg = "none" }
    end,
  },
}
