-- O tema ativo da sessão manda. Quem escreve o arquivo é o script `theme`;
-- aqui só lemos. Sem o arquivo (primeiro boot, nvim fora da sessão Sway),
-- cai no padrão.
local function active()
  local state = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
  local f = io.open(state .. "/theme-nvim")
  if not f then
    return "gruvbox-material"
  end
  local name = f:read("l")
  f:close()
  return (name and name ~= "") and name or "gruvbox-material"
end

return {
  -- Os cinco plugins cobrem os oito temas. Todos lazy: o LazyVim carrega só o
  -- que o colorscheme pedir.
  { "folke/tokyonight.nvim", lazy = true, opts = { style = "night" } },
  { "ellisonleao/gruvbox.nvim", lazy = true, opts = { contrast = "hard", terminal_colors = true } },
  {
    "sainnhe/gruvbox-material",
    lazy = true,
    -- As opções do gruvbox-material são variáveis globais e precisam existir
    -- antes de o tema carregar — daí `init`, e não `config`.
    init = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_better_performance = 1
    end,
  },
  { "wtfox/jellybeans.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },

  { "LazyVim/LazyVim", opts = { colorscheme = active() } },
}
