-- Gruvbox Dark (medium), a mesma paleta do kitty, alacritty, herdr e btop.
-- Os papéis (qual cor vai em qual token) seguem a tabela "Papéis" do README,
-- que é o mapeamento do Gruvbox Dark Medium de jdinhlife vendorizado em vscode/.
local fg1, fg4 = "#ebdbb2", "#a89984"
local red, green, yellow, blue, purple, aqua = "#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#d3869b", "#8ec07c"

-- Sem cor própria para os tokens semânticos do LSP: o treesitter decide, igual
-- ao VSCode, onde o gopls não manda tokens semânticos. Sem isso o gopls pinta o
-- caminho do import como namespace e `interface` como keyword.
local overrides = {}
for _, t in ipairs({
  "class", "comment", "decorator", "enum", "enumMember", "event", "function",
  "interface", "keyword", "macro", "method", "modifier", "namespace", "number",
  "operator", "parameter", "property", "regexp", "string", "struct", "type",
  "typeParameter", "variable",
}) do
  overrides["@lsp.type." .. t] = {}
end

for k, v in pairs({
  -- `import` vermelho como as outras keywords; `package` aqua (captura própria
  -- em after/queries/go/highlights.scm, espelhando a gramática do VSCode)
  ["@keyword.import"] = { fg = red },
  ["@keyword.package"] = { fg = aqua },
  -- struct / interface em azul (captura própria na mesma query)
  ["@keyword.type.struct"] = { fg = blue },
  -- tipos: definidos por você ou de pacote em creme, builtin em amarelo
  ["@type"] = { fg = fg1 },
  ["@type.definition"] = { fg = fg1 },
  ["@type.builtin"] = { fg = yellow },
  -- funções, métodos e builtins (panic, len) em roxo, sem negrito
  Function = { fg = purple },
  ["@function"] = { fg = purple },
  ["@function.call"] = { fg = purple },
  ["@function.method"] = { fg = purple },
  ["@function.method.call"] = { fg = purple },
  ["@function.builtin"] = { fg = purple },
  -- variáveis, parâmetros e campos em azul; nome de pacote (fmt.State) em creme
  ["@variable"] = { fg = blue },
  ["@variable.parameter"] = { fg = blue },
  ["@variable.member"] = { fg = blue },
  ["@property"] = { fg = blue },
  ["@module"] = { fg = fg1 },
  -- constantes, nil, números e escapes em roxo
  ["@constant.builtin"] = { fg = purple },
  ["@string.escape"] = { fg = purple },
  -- operadores em aqua; pontuação em cinza claro (os colchetes ganham a cor do
  -- nível pelo rainbow-delimiters abaixo)
  ["@operator"] = { fg = aqua },
  Operator = { fg = aqua },
  Delimiter = { fg = fg4 },
  ["@punctuation.delimiter"] = { fg = fg4 },
  ["@punctuation.special"] = { fg = fg4 },
  ["@punctuation.bracket"] = { fg = fg4 },
  -- tags HTML/JSX em aqua, atributos em amarelo
  ["@tag"] = { fg = aqua },
  ["@tag.attribute"] = { fg = yellow },
  -- níveis de colchete, os mesmos editorBracketHighlight.foreground1..6 do tema
  RainbowDelimiter1 = { fg = "#b16286" },
  RainbowDelimiter2 = { fg = "#458588" },
  RainbowDelimiter3 = { fg = "#689d6a" },
  RainbowDelimiter4 = { fg = "#98971a" },
  RainbowDelimiter5 = { fg = "#d79921" },
  RainbowDelimiter6 = { fg = "#d65d0e" },
}) do
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
  {
    -- colchetes por nível, como o bracket pair colorization do VSCode
    "HiPhish/rainbow-delimiters.nvim",
    event = "LazyFile",
    init = function()
      vim.g.rainbow_delimiters = {
        highlight = {
          "RainbowDelimiter1", "RainbowDelimiter2", "RainbowDelimiter3",
          "RainbowDelimiter4", "RainbowDelimiter5", "RainbowDelimiter6",
        },
      }
    end,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "gruvbox" } },
}
