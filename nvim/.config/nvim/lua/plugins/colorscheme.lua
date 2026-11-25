-- Catppuccin Mocha com o fundo preto do herdr (#17191d, medido num print do
-- graphite): só base/mantle/crust mudam, as cores de texto são as do Mocha.
-- O herdr-app usa o mesmo par em ~/.config/herdr-app/themes/catppuccin-black.json.
return {
  {
    -- colchetes por nível, como o bracket pair colorization do VSCode; as
    -- cores vêm da integração rainbow_delimiters do catppuccin
    "HiPhish/rainbow-delimiters.nvim",
    event = "LazyFile",
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      color_overrides = {
        mocha = {
          base = "#17191d", -- editor
          mantle = "#131418", -- statusline, explorer, floats
          crust = "#0f1013", -- bordas, separadores
        },
      },
    },
  },
  -- "catppuccin-mocha" e não "catppuccin": o Neovim 0.12 traz um
  -- colors/catppuccin.vim próprio no runtime, que ganharia do plugin.
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-mocha" } },
}
