-- Catppuccin Mocha, a mesma paleta do kitty, alacritty, herdr e btop.
-- Sem overrides: o mapeamento de cores é o do catppuccin/nvim.
return {
  {
    -- colchetes por nível, como o bracket pair colorization do VSCode; as
    -- cores vêm da integração rainbow_delimiters do catppuccin
    "HiPhish/rainbow-delimiters.nvim",
    event = "LazyFile",
  },
  -- "catppuccin-mocha" e não "catppuccin": o Neovim 0.12 traz um
  -- colors/catppuccin.vim próprio no runtime, que ganharia do plugin.
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-mocha" } },
}
