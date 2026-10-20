-- Gruvbox Dark (medium), a mesma paleta do kitty, alacritty, herdr e btop.
-- Os papéis (qual cor vai em qual token) seguem a tabela "Papéis" do README;
-- o tema do VSCode em vscode/ usa a mesma tabela.
local fg1, fg4 = "#ebdbb2", "#a89984"
local red, green, yellow, aqua = "#fb4934", "#b8bb26", "#fabd2f", "#8ec07c"

-- Sem cor própria para os tokens semânticos do LSP: o treesitter decide, igual
-- ao VSCode com semanticHighlighting desligado. Sem isso o gopls pinta o
-- caminho do import como namespace e `interface` como keyword.
local lsp_off = {}
for _, t in ipairs({
  "class", "comment", "decorator", "enum", "enumMember", "event", "function",
  "interface", "keyword", "macro", "method", "modifier", "namespace", "number",
  "operator", "parameter", "property", "regexp", "string", "struct", "type",
  "typeParameter", "variable",
}) do
  lsp_off["@lsp.type." .. t] = {}
end

local overrides = {
  -- package / import em vermelho, como as outras keywords (o gruvbox.nvim usa aqua)
  ["@keyword.import"] = { fg = red },
  -- tipos: definidos por você em creme, builtin (string, int, error) em amarelo
  ["@type"] = { fg = fg1 },
  ["@type.definition"] = { fg = fg1 },
  ["@type.builtin"] = { fg = yellow },
  -- funções e métodos em verde, sem negrito
  Function = { fg = green },
  ["@function"] = { fg = green },
  ["@function.call"] = { fg = green },
  ["@function.method"] = { fg = green },
  ["@function.method.call"] = { fg = green },
  -- builtins (panic, len, append) em vermelho, igual às keywords
  ["@function.builtin"] = { fg = red },
  -- struct / interface em aqua (captura própria em after/queries/go/highlights.scm)
  ["@keyword.type.struct"] = { fg = aqua },
  -- campos de struct e parâmetros em creme
  ["@property"] = { fg = fg1 },
  ["@variable.member"] = { fg = fg1 },
  ["@variable.parameter"] = { fg = fg1 },
  -- pontuação em cinza claro; operadores continuam laranja
  Delimiter = { fg = fg4 },
  ["@punctuation.bracket"] = { fg = fg4 },
  ["@punctuation.delimiter"] = { fg = fg4 },
  ["@punctuation.special"] = { fg = fg4 },
}
for k, v in pairs(lsp_off) do
  overrides[k] = v
end

return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      contrast = "",
      italic = { strings = false, emphasis = true, comments = true, operators = false, folds = true },
      overrides = overrides,
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "gruvbox" } },
}
