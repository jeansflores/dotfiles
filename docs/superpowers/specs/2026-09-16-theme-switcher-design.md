# Trocador de temas para a sessão Sway

Data: 2026-09-16 · Status: aprovado para virar plano de implementação

## 1. Contexto

Hoje cada pacote destes dotfiles guarda os hex do tema no próprio arquivo:
`waybar/style.css` tem um bloco `@define-color` com 16 cores, o `sway/config`
tem quatro linhas `client.*` mais as cores do `wmenu`, o `swaylock/config` tem
vinte, e assim por diante. Trocar de tema é o que fizemos duas vezes nesta
semana — reescrever oito arquivos à mão e commitar.

Isso funciona para uma troca por mês. Não funciona para escolher o tema pelo
humor do dia.

## 2. Objetivo

Um trocador de temas operado pela waybar: ícone de paleta, clique abre um menu,
o tema muda. Os temas ficam versionados nos dotfiles; **trocar de tema não pode
sujar o repositório**.

Critérios de sucesso:

1. `theme set <slug>` aplica o tema em toda a sessão e recarrega o que dá.
2. Um clique no ícone da paleta faz o mesmo, com menu.
3. `git status` continua limpo depois de trocar de tema quantas vezes for.
4. Adicionar um nono tema é escrever **um** manifesto — mais o arquivo de
   paleta do ghostty, nos casos em que o ghostty não traz o tema.

## 3. Decisões já tomadas

| Decisão | Motivo |
| --- | --- |
| Gerar os arquivos de cor na hora da troca (abordagem "A") | 6 templates + 8 manifestos, contra ~48 arquivos se cada tema guardasse os arquivos prontos. Estrutura vive num lugar só. |
| Os arquivos gerados moram **fora** do repositório | É o que garante o critério 3. Eles são derivados, não escritos — não pertencem ao git. |
| Os 16 papéis de cor são **escritos à mão** por tema, não derivados do ANSI | Derivar por heurística dá barra "ok"; escrever à mão dá barra deliberada, como a que foi feita para o Gruvbox Material (onde se conferiu que nenhum par de módulos vizinhos repete cor). |
| Imitar o pacote `powerprofile` | Mesmo problema já resolvido neste repo: script + estado + menu wofi + módulo na waybar. Nada de inventar um segundo padrão. |
| GTK fica fora | Exigiria `gruvbox-gtk-theme` do AUR e não tem equivalente para os oito temas. |

## 4. Os oito temas

| slug | label | ghostty | nvim | btop |
| --- | --- | --- | --- | --- |
| `tokyo-night` | Tokyo Night | `TokyoNight Night` | `tokyonight-night` | `tokyo-night` |
| `gruvbox-hard` | Gruvbox Dark Hard | `Gruvbox Dark Hard` | `gruvbox` | `gruvbox_dark` |
| `gruvbox-material` | Gruvbox Material | `Gruvbox Material Dark` + `background = #1d2021` | `gruvbox-material` | `gruvbox_material_dark` |
| `jellybeans-muted` | Jellybeans Muted | arquivo vendorizado | `jellybeans-muted` | gerado |
| `jellybeans-mono` | Jellybeans Mono | arquivo vendorizado | `jellybeans-mono` | gerado |
| `jellybeans-hc` | Jellybeans HC | arquivo vendorizado | `jellybeans-hc` | gerado |
| `kanagawa-wave` | Kanagawa Wave | `Kanagawa Wave` | `kanagawa-wave` | `kanagawa-wave` |
| `kanagawa-dragon` | Kanagawa Dragon | `Kanagawa Dragon` | `kanagawa-dragon` | `kanagawa-dragon` |

O `gruvbox_dark` do btop tem `main_bg = #1d2021`, que é a variante *hard* — o
`gruvbox_dark_v2` é o *medium* e não serve.

Os três jellybeans são os únicos que o ghostty não traz. O plugin
`wtfox/jellybeans.nvim` publica os arquivos em `extras/ghostty`; eles entram
vendorizados em `theme/.local/share/theme/ghostty/`, com a origem registrada num
README ao lado.

## 5. Arquitetura

### 5.1 O manifesto

Um arquivo por tema, `chave=valor`, lido com `source` pelo script.

```sh
# theme/.local/share/theme/themes/gruvbox-material.theme
label="Gruvbox Material"

# Exatamente um entre ghostty_theme e ghostty_file
ghostty_theme="Gruvbox Material Dark"
ghostty_file=""
ghostty_extra="background = #1d2021"    # opcional, aplicado depois do tema

nvim_colorscheme="gruvbox-material"
btop_theme="gruvbox_material_dark"      # vazio = o script gera de 5.5

bg_dark=#1d2021   bg=#282828      bg_hl=#3c3836
fg=#d4be98        fg_dim=#a89984  comment=#7c6f64
blue=#7daea3      blue1=#7daea3   cyan=#89b482
magenta=#d3869b   purple=#d3869b  green=#a9b665
yellow=#d8a657    orange=#e78a4e  red=#ea6962
teal=#89b482
```

Os 16 papéis são os mesmos nomes que a waybar já usa. Não é coincidência: os
templates nascem dos arquivos atuais, idênticos, com o hex trocado pelo
marcador. O diff da migração precisa ser legível.

Como preencher os 16 para um tema novo: partir do arquivo de tema do ghostty
(que dá `background`, `foreground` e `palette = 0..15`), depois escolher à mão
os três níveis de fundo (`bg_dark` < `bg` < `bg_hl`) e os dois de texto (`fg`,
`fg_dim`), e por fim conferir na ordem dos módulos da barra que nenhum vizinho
caiu na mesma cor.

### 5.2 Templates

Um por app, em `theme/.local/share/theme/templates/`. São os arquivos de hoje
com `@papel@` no lugar do hex:

```css
/* templates/waybar.css */
@define-color bg        @bg@;
@define-color bg_dark   @bg_dark@;
...
```

A renderização é substituição literal de `@papel@`. Sem linguagem de template,
sem dependência nova.

### 5.3 O script `theme`

Em `theme/.local/bin/theme`, bash, mesmo formato do `powerprofile`.

```
theme get             imprime o slug ativo
theme set <slug>      aplica e recarrega
theme cycle           avança para o próximo da lista
theme menu            menu wofi
theme list            slugs disponíveis
theme waybar          JSON para o módulo custom/theme
theme doctor          confere se tudo que devia ser gerado existe
```

Algoritmo do `set`:

1. Valida o slug. Desconhecido → sai com código 2 imprimindo a lista.
2. Dá `source` no manifesto. Falta papel obrigatório → aborta **antes** de
   escrever qualquer coisa.
3. Renderiza cada template para `$(mktemp)` e só então `mv` para o destino.
   Uma falha no meio nunca deixa um CSS pela metade.
4. Edita `color_theme` no `btop.conf` com `sed`.
5. Grava `~/.local/state/theme`, `~/.local/state/theme.env` e
   `~/.local/state/theme-nvim`.
6. Recarrega: `swaymsg reload`, `pkill -SIGUSR2 waybar`, `swaync-client -rs`.

O `SIGUSR2` recarrega config **e** CSS da waybar, e no caminho já re-executa o
módulo — por isso o `set` não manda `RTMIN+10`. O sinal 10 fica declarado no
módulo por simetria com o `powerprofile` e para refrescar só o rótulo quando
não houver CSS novo.

### 5.4 O que é gerado

Tudo fora do repositório:

| Arquivo | Conteúdo |
| --- | --- |
| `~/.config/waybar/colors.css` | os 16 `@define-color` |
| `~/.config/sway/colors.conf` | `client.*`, `set $menu`, `output * bg` |
| `~/.config/swaync/colors.css` | os `@define-color` que o swaync usa |
| `~/.config/wofi/style.css` | o arquivo **inteiro** — ver a correção abaixo |
| `~/.config/swaylock/config` | o arquivo inteiro — swaylock não tem `include` |
| `~/.config/ghostty/theme.conf` | `theme = …` ou o arquivo vendorizado, mais o `ghostty_extra` |
| `~/.config/btop/themes/current.theme` | só quando `btop_theme` está vazio |
| `~/.local/state/theme` | o slug ativo |
| `~/.local/state/theme.env` | os 16 papéis como variáveis, para o `screenrec` |
| `~/.local/state/theme-nvim` | uma linha: o nome do colorscheme |

> **Correção, descoberta na implementação.** O wofi estava previsto para usar
> `@import` como a waybar e o swaync. Não funciona: o wofi carrega o CSS por
> *conteúdo* (`<data>`), não por caminho, então um `@import` relativo resolve
> contra o diretório de trabalho de quem lançou o wofi. Lançado pela barra, o
> import falha calado, as cores ficam indefinidas, o GTK descarta as regras e os
> menus saem **transparentes**. O `style.css` do wofi passou a ser gerado
> inteiro, com cor literal, e o pacote stow `wofi` foi removido como o
> `swaylock`. A waybar e o swaync carregam por caminho e continuam com `@import`.

### 5.5 Tema de btop gerado

Quando o btop não traz o tema (os três jellybeans), o script escreve as 38
chaves `theme[...]` a partir dos 16 papéis. O mapeamento fica no template
`templates/btop.theme`; as chaves de gradiente (`cpu_start/mid/end` e afins)
saem dos papéis `green`, `yellow` e `red`.

### 5.6 O módulo na waybar

```jsonc
"custom/theme": {
    "exec": "$HOME/.local/bin/theme waybar",
    "return-type": "json",
    "signal": 10,
    "format": "{}",
    "on-click": "$HOME/.local/bin/theme menu",
    "on-click-right": "$HOME/.local/bin/theme cycle"
}
```

Os sinais 8 e 9 já são do `powerprofile` e do `custom/recording`; o tema fica no
10. O módulo entra à esquerda do `custom/powerprofile`, que é o vizinho lógico.

`theme waybar` devolve:

```json
{"text":"󰏘","tooltip":"Tema: Gruvbox Material","class":"gruvbox-material"}
```

O glyph de paleta é Nerd Font dentro de JSON: vai escrito como `\uXXXX` e é
conferido com `xxd` mais uma captura `grim`. Escrever o caractere direto no
heredoc já quebrou antes neste repo.

O `theme menu` usa `wofi --dmenu`, com os labels dos oito temas e o ativo
marcado — mesmo formato do `powerprofile menu`.

## 6. Mudanças por pacote

| Pacote | O que acontece |
| --- | --- |
| `theme` | **nasce**: script, 8 manifestos, 7 templates, 3 arquivos de ghostty vendorizados |
| `swaylock` | **morre**: o config passa a ser gerado |
| `waybar` | `style.css` troca o bloco de cores por `@import`; `config.jsonc` ganha o módulo |
| `sway` | as cores saem para `colors.conf`, incluído no config (ver nota abaixo) |
| `swaync`, `wofi` | trocam o bloco de cores por `@import` |
| `ghostty` | `theme = …` vira `config-file = theme.conf` |
| `nvim` | ver seção 7 |
| `screenrec` | as cores do `slurp` passam a sair do `theme.env` |
| `btop` | `color_theme` passa a ser escrito pelo script |
| `install-deps.sh` | `theme` entra na lista do stow e um `theme set` roda no fim |

**O `include` do sway não pode ir para o fim do arquivo.** O sway resolve
variáveis na hora do parse, e o `colors.conf` define `$menu`, usado lá em cima
no `bindsym $mod+d`. O `include` tem que vir antes desse primeiro uso — e não
junto do `include /etc/sway/config.d/*`, que fica na última linha.

## 7. Neovim

Cinco plugins cobrem os oito temas:

| Plugin | Temas |
| --- | --- |
| `folke/tokyonight.nvim` | `tokyo-night` |
| `ellisonleao/gruvbox.nvim` | `gruvbox-hard` |
| `sainnhe/gruvbox-material` | `gruvbox-material` |
| `wtfox/jellybeans.nvim` | os três jellybeans |
| `rebelot/kanagawa.nvim` | wave e dragon |

Todos declarados `lazy = true`; o LazyVim carrega só o que o `colorscheme`
pedir. As opções específicas (o `contrast = "hard"` do gruvbox.nvim, o
`background`/`foreground` do gruvbox-material) são fixas por plugin e continuam
na spec do plugin — o que varia é só o nome do colorscheme.

`lua/plugins/colorscheme.lua` lê `~/.local/state/theme-nvim`:

```lua
local function active()
  local f = io.open(vim.env.HOME .. "/.local/state/theme-nvim")
  if not f then return "gruvbox-material" end
  local name = f:read("l")
  f:close()
  return (name and name ~= "") and name or "gruvbox-material"
end
```

Instância de nvim já aberta **não** troca de tema; só a próxima.

## 8. Erros e modos de falha

| Situação | Comportamento |
| --- | --- |
| Slug desconhecido | Código 2, imprime a lista de slugs |
| Manifesto sem um papel obrigatório | Aborta antes de escrever; nada é alterado |
| Template faltando | Idem |
| Estado ausente (primeiro boot) | Cai em `gruvbox-material` |
| Arquivo gerado apagado à mão | **A waybar sobe sem estilo nenhum, sem mensagem de erro.** É o modo de falha chato, e é para isso que o `theme doctor` existe |

## 9. Verificação

Para cada um dos oito slugs, depois de `theme set`:

1. Nenhum `@papel@` sobrando em nenhum arquivo gerado — `grep -r '@[a-z_]*@'`.
2. `ghostty +show-config` devolve o `background` esperado.
3. `nvim --headless` devolve o `colors_name` esperado.
4. btop capturado num pty do tmux (`tmux new-session -d -x 200 -y 50 btop`,
   depois `capture-pane -e`) mostra as cores esperadas.
5. `grim` da barra para conferência visual.
6. `git status` limpo ao fim das oito trocas — é o critério 3.

Mais `bash -n` e `shellcheck` no script, e `swaymsg reload` sem erro.

Os itens 2 a 5 já foram usados nesta sessão e funcionam.

## 10. Fora de escopo

- GTK: continua Adwaita com `prefer-dark`.
- Temas claros: nenhum dos oito é claro; a alternância claro/escuro exigiria
  mexer no `prefer-dark` e nos ícones Papirus-Dark.
- `tmux` e `herdr`: seguem herdando do ghostty de graça, sem cor própria.

## 11. Riscos conhecidos

1. **Ghostty aberto não troca sozinho.** Não há sinal documentado; existe o
   keybind padrão `ctrl+shift+,` (`reload_config`). Vale testar `SIGUSR2` na
   implementação, mas o desenho não depende disso.
2. **O btop reescreve o `btop.conf` ao sair limpo.** Como o arquivo está no
   stow, abrir o monitor pela barra suja o repositório sozinho — já documentado
   no README. Se virar incômodo depois do trocador, a saída é tirar o `btop.conf`
   do stow e deixar o script como único dono da linha `color_theme`.
3. **Os 16 papéis de cinco temas ainda não existem.** Três já estão escritos e
   só precisam ser extraídos: `gruvbox-material` da árvore atual,
   `gruvbox-hard` do commit `a7d8821`, e `tokyo-night` de `e8f9b33` (o último
   commit antes da migração). Os cinco restantes — três jellybeans e dois
   kanagawa — são trabalho manual de verdade, e são a maior fatia da
   implementação.
