# Trocador de temas — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar o tema de toda a sessão Sway por um clique na waybar, com os temas versionados nos dotfiles e sem sujar o repositório.

**Architecture:** Um manifesto por tema (16 papéis de cor + nomes para ghostty/nvim/btop) e um template por app. O script `theme` renderiza os templates para `~/.config/…`, fora do repositório, grava o estado em `~/.local/state` e recarrega o que aceita reload em quente. Mesma forma do pacote `powerprofile`, que já resolve esse problema aqui.

**Tech Stack:** bash, GNU stow, GTK CSS (`@import`/`@define-color`), sway `include`, ghostty `config-file`, wofi `--dmenu`, lazy.nvim.

**Spec:** `docs/superpowers/specs/2026-09-16-theme-switcher-design.md`

## Global Constraints

- Trocar de tema **não pode** deixar `git status` sujo. Todo arquivo renderizado vai para fora do repositório.
- Os 16 papéis são exatamente: `bg_dark bg bg_hl fg fg_dim comment blue blue1 cyan magenta purple green yellow orange red teal`. Não inventar nomes novos.
- Renderizar sempre para `mktemp` e só então `mv`. Nenhuma escrita parcial em arquivo de config.
- **Todo arquivo novo no pacote `theme` pede `stow --no-folding theme` de novo.** O `--no-folding` cria um symlink por arquivo, então template criado depois do último stow simplesmente não existe em `~/.local/share/theme/` e o `theme set` morre com "template faltando".
- **Nunca rode `sed -i` num caminho dentro de `~/.local/share/theme/` ou `~/.config/`.** São symlinks do stow, e o `sed -i` troca o symlink por arquivo comum, quebrando a ligação com o repositório. Edite o arquivo no repo e restaure com `git checkout`.
- **Não mande sinal nenhum para a waybar** — nem `SIGUSR2`, nem `RTMIN+N`. Ela sobe por `swaybar_command`, então o `swaymsg reload` já a respawna e o módulo re-executa junto. O sinal chega no processo recém nascido antes do handler existir, e o default é terminar: medido 1 morte em 5 trocas com `RTMIN+10`, 0 em 10 sem. O `powerprofile` pode mandar sinal porque o `set` dele não reloada o sway.
- Glyph Nerd Font dentro de JSON vai escrito como `\uXXXX` e é conferido com `xxd`. Caractere literal em heredoc já quebrou neste repo.
- Commits em inglês, Conventional Commits (`feat(scope): …`), mesmo o resto sendo pt-BR.
- Não commitar sem perguntar. Cada task termina em "deixe na working tree e peça revisão", não em `git commit` automático.

---

### Task 1: Esqueleto do pacote `theme` + primeiro app (waybar)

Entrega: `theme set gruvbox-material` gera `~/.config/waybar/colors.css` e a waybar recarrega com as cores certas.

**Files:**
- Create: `theme/.local/bin/theme`
- Create: `theme/.local/share/theme/themes/gruvbox-material.theme`
- Create: `theme/.local/share/theme/templates/waybar.css`
- Create: `tests/theme-test.sh`
- Modify: `waybar/.config/waybar/style.css:1-22` (bloco de cores vira `@import`)

**Interfaces:**
- Produces: o script `theme` com os subcomandos `list`, `get`, `set <slug>`; a função interna `render <template> <destino>`; o diretório de dados `~/.local/share/theme/{themes,templates}`; o estado `~/.local/state/theme`.
- Consumes: nada.

- [ ] **Step 1: Escreva o teste que falha**

Crie `tests/theme-test.sh`:

```bash
#!/usr/bin/env bash
# Testa o trocador de temas contra a sessão viva.
#   ./tests/theme-test.sh           todos os temas
#   ./tests/theme-test.sh <slug>    só um
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
THEME="$HOME/.local/bin/theme"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
fails=0

ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
bad()  { printf '  \033[31mFALHOU\033[0m %s\n' "$*"; fails=$((fails + 1)); }

# assert_file <caminho> — existe e não está vazio
assert_file() {
    if [[ -s "$1" ]]; then ok "existe e não está vazio: $1"; else bad "faltando ou vazio: $1"; fi
}

# assert_no_placeholder <caminho> — nenhum @papel@ sobrando
assert_no_placeholder() {
    local hits
    hits=$(grep -oE '@[a-z_]+@' "$1" 2>/dev/null | sort -u | tr '\n' ' ')
    if [[ -z "$hits" ]]; then ok "sem marcador sobrando: $1"; else bad "marcador não substituído em $1: $hits"; fi
}

GENERATED=(
    "$HOME/.config/waybar/colors.css"
)

test_slug() {
    local slug=$1
    printf '\n\033[1m== %s ==\033[0m\n' "$slug"
    if ! "$THEME" set "$slug" >/dev/null 2>&1; then bad "theme set $slug saiu com erro"; return; fi
    ok "theme set $slug"

    [[ "$("$THEME" get)" == "$slug" ]] && ok "theme get devolve $slug" || bad "theme get não devolve $slug"

    local f
    for f in "${GENERATED[@]}"; do
        assert_file "$f"
        assert_no_placeholder "$f"
    done
}

slugs=("${@:-}")
[[ -z "${slugs[0]}" ]] && mapfile -t slugs < <("$THEME" list)

for s in "${slugs[@]}"; do test_slug "$s"; done

printf '\n\033[1m== repositório ==\033[0m\n'
if [[ -z "$(git -C "$REPO" status --porcelain)" ]]; then
    ok "git status limpo depois de trocar de tema"
else
    bad "trocar de tema sujou o repositório:"
    git -C "$REPO" status --short | sed 's/^/        /'
fi

printf '\n%s\n' "$([[ $fails -eq 0 ]] && printf '\033[32mtudo passou\033[0m' || printf "\033[31m$fails falha(s)\033[0m")"
exit $(( fails > 0 ))
```

```bash
chmod +x tests/theme-test.sh
```

- [ ] **Step 2: Rode o teste e confirme que falha**

Run: `./tests/theme-test.sh gruvbox-material`
Expected: FALHOU — `theme set` sai com erro, porque `~/.local/bin/theme` ainda não existe.

- [ ] **Step 3: Escreva o manifesto**

Crie `theme/.local/share/theme/themes/gruvbox-material.theme`:

```sh
label="Gruvbox Material"

ghostty_theme="Gruvbox Material Dark"
ghostty_file=""
ghostty_extra="background = #1d2021"

nvim_colorscheme="gruvbox-material"
btop_theme="gruvbox_material_dark"

bg_dark=#1d2021
bg=#282828
bg_hl=#3c3836
fg=#d4be98
fg_dim=#a89984
comment=#7c6f64
blue=#7daea3
blue1=#7daea3
cyan=#89b482
magenta=#d3869b
purple=#d3869b
green=#a9b665
yellow=#d8a657
orange=#e78a4e
red=#ea6962
teal=#89b482
```

- [ ] **Step 4: Escreva o template da waybar**

Crie `theme/.local/share/theme/templates/waybar.css` — é o bloco que está hoje em `waybar/.config/waybar/style.css:1-22`, com o hex trocado pelo marcador:

```css
/* Gerado por `theme set`. Não edite: mexa no manifesto do tema. */

@define-color bg        @bg@;
@define-color bg_dark   @bg_dark@;
@define-color bg_hl     @bg_hl@;
@define-color fg        @fg@;
@define-color fg_dim    @fg_dim@;
@define-color comment   @comment@;
@define-color blue      @blue@;
@define-color blue1     @blue1@;
@define-color cyan      @cyan@;
@define-color magenta   @magenta@;
@define-color purple    @purple@;
@define-color green     @green@;
@define-color yellow    @yellow@;
@define-color orange    @orange@;
@define-color red       @red@;
@define-color teal      @teal@;
```

- [ ] **Step 5: Escreva o script**

Crie `theme/.local/bin/theme`:

```bash
#!/usr/bin/env bash
#
# theme — troca o tema da sessão Sway.
#
#   theme get             slug ativo
#   theme set <slug>      aplica e recarrega
#   theme list            slugs disponíveis
#
# Os temas ficam em ~/.local/share/theme/themes/<slug>.theme e os templates em
# ~/.local/share/theme/templates/. Tudo que este script escreve mora fora do
# repositório de dotfiles — trocar de tema nunca deve sujar o git.
set -euo pipefail

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/theme"
THEMES_DIR="$DATA_DIR/themes"
TEMPLATES_DIR="$DATA_DIR/templates"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/theme"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

DEFAULT_THEME=gruvbox-material

# Os 16 papéis que todo manifesto precisa ter.
ROLES=(bg_dark bg bg_hl fg fg_dim comment blue blue1 cyan magenta purple
       green yellow orange red teal)

die() { printf 'theme: %s\n' "$*" >&2; exit 1; }

cmd_list() {
    local f
    for f in "$THEMES_DIR"/*.theme; do
        [[ -e "$f" ]] || continue
        basename "$f" .theme
    done
}

cmd_get() {
    local slug=""
    [[ -r "$STATE_FILE" ]] && slug=$(tr -d '[:space:]' < "$STATE_FILE")
    [[ -n "$slug" ]] || slug=$DEFAULT_THEME
    printf '%s\n' "$slug"
}

# load <slug> — valida e dá source no manifesto, exportando os papéis.
load() {
    local slug=$1 manifest="$THEMES_DIR/$1.theme"
    [[ -r "$manifest" ]] || {
        printf 'theme: tema desconhecido: %s\n\ndisponíveis:\n' "$slug" >&2
        cmd_list | sed 's/^/  /' >&2
        exit 2
    }
    # shellcheck source=/dev/null
    source "$manifest"

    local role
    for role in "${ROLES[@]}"; do
        [[ -n "${!role:-}" ]] || die "manifesto $slug não define o papel '$role'"
    done
}

# render <template> <destino> — substitui @papel@ e move atomicamente.
render() {
    local tpl="$TEMPLATES_DIR/$1" dest=$2 tmp
    [[ -r "$tpl" ]] || die "template faltando: $tpl"

    local -a sed_args=()
    local role
    for role in "${ROLES[@]}"; do
        sed_args+=(-e "s|@${role}@|${!role}|g")
    done

    tmp=$(mktemp)
    sed "${sed_args[@]}" "$tpl" > "$tmp"
    mkdir -p "$(dirname "$dest")"
    mv "$tmp" "$dest"
}

reload() {
    # A waybar sobe por `swaybar_command`, então o reload do sway já a respawna
    # com config e CSS novos. Nada de SIGUSR2: redundante e cria corrida.
    swaymsg reload    >/dev/null 2>&1 || true
    swaync-client -rs >/dev/null 2>&1 || true
}

cmd_set() {
    local slug=${1:-}
    [[ -n "$slug" ]] || die "uso: theme set <slug>"
    load "$slug"

    render waybar.css "$CONFIG_DIR/waybar/colors.css"

    mkdir -p "$STATE_DIR"
    printf '%s\n' "$slug" > "$STATE_FILE"

    reload
}

case "${1:-get}" in
    get)  cmd_get ;;
    list) cmd_list ;;
    set)  shift; cmd_set "$@" ;;
    *)    printf 'uso: %s {get|set <slug>|list}\n' "$(basename "$0")" >&2; exit 1 ;;
esac
```

```bash
chmod +x theme/.local/bin/theme
```

- [ ] **Step 6: Aponte a waybar para o arquivo gerado**

Em `waybar/.config/waybar/style.css`, substitua todo o bloco das linhas 1–22 (o comentário do cabeçalho e os 16 `@define-color`) por:

```css
/* Waybar — as cores vêm do tema ativo, gerado por `theme set`.
 * Paleta e temas: ~/.local/share/theme/
 */
@import "colors.css";
```

O resto do arquivo não muda: continua usando `@bg`, `@fg`, `@blue` etc.

- [ ] **Step 6b: Escreva os testes dos caminhos de erro**

A seção 8 do spec exige que erro nunca escreva nada pela metade. Some ao fim de
`tests/theme-test.sh`, antes do bloco `== repositório ==`:

```bash
printf '\n\033[1m== erros ==\033[0m\n'

# slug desconhecido sai com 2 e não toca em nada
before=$(cat "$HOME/.config/waybar/colors.css" 2>/dev/null)
"$THEME" set nao-existe >/dev/null 2>&1
rc=$?
[[ $rc -eq 2 ]] && ok "slug desconhecido sai com 2" || bad "slug desconhecido saiu com $rc, esperava 2"
after=$(cat "$HOME/.config/waybar/colors.css" 2>/dev/null)
[[ "$before" == "$after" ]] && ok "slug desconhecido não mexeu nos arquivos" || bad "slug desconhecido alterou colors.css"

# manifesto sem um papel aborta antes de escrever
tmp_manifest="$HOME/.local/share/theme/themes/zz-teste.theme"
grep -v '^blue=' "$HOME/.local/share/theme/themes/gruvbox-material.theme" > "$tmp_manifest"
before=$(cat "$HOME/.config/waybar/colors.css" 2>/dev/null)
"$THEME" set zz-teste >/dev/null 2>&1
rc=$?
[[ $rc -ne 0 ]] && ok "manifesto incompleto falha (rc=$rc)" || bad "manifesto sem 'blue' passou"
after=$(cat "$HOME/.config/waybar/colors.css" 2>/dev/null)
[[ "$before" == "$after" ]] && ok "manifesto incompleto não escreveu nada" || bad "manifesto incompleto sujou colors.css"
rm -f "$tmp_manifest"
```

- [ ] **Step 7: Aplique o stow e rode o teste**

```bash
cd ~/dotfiles && stow --no-folding theme
./tests/theme-test.sh gruvbox-material
```

Expected: PASSA — `theme set`, `theme get`, `colors.css` existe, sem marcador sobrando, git limpo.

- [ ] **Step 8: Confira na tela**

```bash
grim -o eDP-1 /tmp/theme-task1.png
```

A barra tem que estar idêntica à de antes (mesmo tema, só que agora vindo do arquivo gerado). Se ela subiu **sem estilo nenhum**, o `@import` não achou o `colors.css` — é o modo de falha descrito na seção 8 do spec.

- [ ] **Step 9: Deixe na working tree e peça revisão**

Não commite. Mostre `git status --short` e o print, e pergunte se pode commitar como:

```
feat(theme): add theme package with waybar colors generated per theme
```

---

### Task 2: sway, swaync e wofi

Entrega: os três apps que aceitam include/`@import` passam a pegar cor do tema ativo.

**Files:**
- Create: `theme/.local/share/theme/templates/sway.conf`
- Create: `theme/.local/share/theme/templates/swaync.css`
- Create: `theme/.local/share/theme/templates/wofi.css`
- Modify: `theme/.local/bin/theme` (três chamadas novas de `render` em `cmd_set`)
- Modify: `sway/.config/sway/config` (tira as cores, põe o `include`)
- Modify: `swaync/.config/swaync/style.css:1-11`
- Modify: `wofi/.config/wofi/style.css` (hex vira `@papel`)
- Modify: `tests/theme-test.sh` (array `GENERATED`)

**Interfaces:**
- Consumes: `render`, `load`, `ROLES` da Task 1.
- Produces: `~/.config/sway/colors.conf`, `~/.config/swaync/colors.css`, `~/.config/wofi/colors.css`.

- [ ] **Step 1: Estenda o teste**

Em `tests/theme-test.sh`, troque o array `GENERATED` por:

```bash
GENERATED=(
    "$HOME/.config/waybar/colors.css"
    "$HOME/.config/sway/colors.conf"
    "$HOME/.config/swaync/colors.css"
    "$HOME/.config/wofi/colors.css"
)
```

- [ ] **Step 2: Rode e confirme que falha**

Run: `./tests/theme-test.sh gruvbox-material`
Expected: FALHOU — três arquivos faltando.

- [ ] **Step 3: Escreva `templates/sway.conf`**

```
# Gerado por `theme set`. Não edite: mexa no manifesto do tema.

set $menu wmenu-run -i -f "Noto Sans 11" -N '@bg_dark@' -n '@fg@' -M '@magenta@' -m '@bg_dark@' -S '@blue@' -s '@bg_dark@'

output * bg @bg_dark@ solid_color

# Cores das bordas:      borda      fundo      texto      indicador  borda-filho
client.focused           @blue@     @blue@     @bg_dark@  @magenta@  @blue@
client.focused_inactive  @bg_hl@    @bg_hl@    @fg_dim@   @bg_hl@    @bg_hl@
client.unfocused         @bg@       @bg@       @comment@  @bg@       @bg_hl@
client.urgent            @red@      @red@      @bg_dark@  @red@      @red@
client.background        @bg_dark@
```

- [ ] **Step 4: Escreva `templates/swaync.css`**

```css
/* Gerado por `theme set`. Não edite: mexa no manifesto do tema. */

@define-color bg        @bg@;
@define-color bg_dark   @bg_dark@;
@define-color bg_hl     @bg_hl@;
@define-color fg        @fg@;
@define-color fg_dim    @fg_dim@;
@define-color comment   @comment@;
@define-color blue      @blue@;
@define-color magenta   @magenta@;
@define-color red       @red@;
```

- [ ] **Step 5: Escreva `templates/wofi.css`**

O wofi hoje usa hex cru. Este template define os papéis; o `style.css` passa a referenciá-los.

```css
/* Gerado por `theme set`. Não edite: mexa no manifesto do tema. */

@define-color bg        @bg@;
@define-color bg_dark   @bg_dark@;
@define-color bg_hl     @bg_hl@;
@define-color fg        @fg@;
@define-color fg_dim    @fg_dim@;
@define-color blue      @blue@;
```

- [ ] **Step 6: Ligue os três no `cmd_set`**

Em `theme/.local/bin/theme`, dentro de `cmd_set`, logo depois da linha do `waybar.css`:

```bash
    render sway.conf  "$CONFIG_DIR/sway/colors.conf"
    render swaync.css "$CONFIG_DIR/swaync/colors.css"
    render wofi.css   "$CONFIG_DIR/wofi/colors.css"
```

- [ ] **Step 7: Ajuste o config do sway**

Duas edições em `sway/.config/sway/config`:

1. Apague a linha 19 (`set $menu wmenu-run …`) e o comentário acima dela. No lugar, ponha:

```
# Cores, wallpaper e o lançador vêm do tema ativo (`theme set`).
# Precisa vir ANTES do primeiro uso de $menu, lá no bindsym $mod+d — o sway
# resolve variáveis na hora do parse.
include ~/.config/sway/colors.conf
```

2. Apague o bloco `# Aparência — …` com as cinco linhas `client.*`, e a linha `output * bg #1d2021 solid_color` junto do comentário do wallpaper. Tudo isso agora vive no `colors.conf`.

- [ ] **Step 8: Ajuste swaync e wofi**

Em `swaync/.config/swaync/style.css`, troque as linhas 1–11 por:

```css
/* SwayNC — as cores vêm do tema ativo, gerado por `theme set`. */
@import "colors.css";
```

Em `wofi/.config/wofi/style.css`, ponha no topo:

```css
/* Wofi — as cores vêm do tema ativo, gerado por `theme set`. */
@import "colors.css";
```

e troque cada hex pelo papel correspondente:

| Linha | Hex hoje | Vira |
| --- | --- | --- |
| 4 | `#1d2021` | `@bg_dark` |
| 5 | `#3c3836` | `@bg_hl` |
| 16 | `#282828` | `@bg` |
| 17 | `#d4be98` | `@fg` |
| 18 | `#3c3836` | `@bg_hl` |
| 25 | `#7daea3` | `@blue` |
| 39 | `#a89984` | `@fg_dim` |
| 43 | `#7daea3` | `@blue` |
| 44 | `#1d2021` | `@bg_dark` |
| 52 | `#1d2021` | `@bg_dark` |

- [ ] **Step 9: Rode o teste**

Run: `./tests/theme-test.sh gruvbox-material`
Expected: PASSA nos quatro arquivos.

- [ ] **Step 10: Confira que o sway não reclamou**

```bash
swaymsg reload && echo "reload OK"
swaymsg -t get_config --raw | grep -c 'client.focused '
```

Expected: `reload OK` e contagem ≥ 1 — prova que o `include` foi lido.
Abra o lançador com `$mod+d`: se ele subir preto-e-branco, o `include` ficou depois do `bindsym`.

- [ ] **Step 11: Deixe na working tree e peça revisão**

```
feat(theme): move sway, swaync and wofi colors into the theme package
```

---

> **Correção aplicada depois da Task 10.** Os passos da Task 2 abaixo mandam o
> wofi usar `@import "colors.css"`. Isso deixa os menus transparentes: o wofi
> carrega CSS por conteúdo, e o import relativo resolve contra o diretório de
> trabalho errado. O correto é gerar o `style.css` do wofi inteiro, com cor
> literal, e remover o pacote stow `wofi`. Ver a correção na seção 5.4 do spec.

### Task 3: swaylock gerado

Entrega: o `swaylock/config` vira arquivo gerado e o pacote stow `swaylock` some.

**Files:**
- Create: `theme/.local/share/theme/templates/swaylock.conf`
- Delete: `swaylock/` (pacote inteiro)
- Modify: `theme/.local/bin/theme`
- Modify: `install-deps.sh` (tira `swaylock` da linha do stow)
- Modify: `tests/theme-test.sh`

**Interfaces:**
- Consumes: `render` da Task 1.
- Produces: `~/.config/swaylock/config`.

- [ ] **Step 1: Estenda o teste**

Some `"$HOME/.config/swaylock/config"` ao array `GENERATED`.

- [ ] **Step 2: Rode e confirme que falha**

Run: `./tests/theme-test.sh gruvbox-material`
Expected: FALHOU — o arquivo existe, mas é o symlink do stow; o teste ainda passa nesse ponto. Para ver a falha de verdade, rode antes `stow -D swaylock` — aí o arquivo some e o teste acusa.

- [ ] **Step 3: Escreva `templates/swaylock.conf`**

O swaylock quer hex **sem** `#`, então o template usa os papéis já sem cerquilha — o `render` substitui `@bg_dark@` por `#1d2021`, então aqui a cerquilha precisa ser removida depois. Para não inventar uma segunda forma de substituição, o template escreve a cor completa e o `cmd_set` roda um `sed` extra tirando o `#` nas linhas `*-color=`:

```
# Gerado por `theme set`. Não edite: mexa no manifesto do tema.

daemonize
ignore-empty-password
show-failed-attempts
indicator-caps-lock
indicator-radius=100
indicator-thickness=8

color=@bg_dark@

inside-color=@bg_dark@
inside-clear-color=@bg_dark@
inside-ver-color=@bg_dark@
inside-wrong-color=@bg_dark@

ring-color=@bg_hl@
ring-clear-color=@yellow@
ring-ver-color=@blue@
ring-wrong-color=@red@

key-hl-color=@magenta@
bs-hl-color=@orange@

line-color=00000000
line-clear-color=00000000
line-ver-color=00000000
line-wrong-color=00000000
separator-color=00000000

text-color=@fg@
text-clear-color=@yellow@
text-ver-color=@blue@
text-wrong-color=@red@

font=Noto Sans
font-size=20
```

- [ ] **Step 4: Ligue no `cmd_set`, com o tratamento da cerquilha**

Em `cmd_set`:

```bash
    render swaylock.conf "$CONFIG_DIR/swaylock/config"
    # O swaylock quer os hex sem '#'.
    sed -i -E 's/^([a-z-]*color)=#/\1=/' "$CONFIG_DIR/swaylock/config"
```

- [ ] **Step 5: Mate o pacote stow**

```bash
cd ~/dotfiles
stow -D swaylock
git rm -r swaylock
```

Em `install-deps.sh`, tire `swaylock` da linha do `stow --no-folding` (o **pacote**; o `swaylock` da lista `PKGS` continua, que é o programa).

- [ ] **Step 6: Rode o teste**

Run: `./tests/theme-test.sh gruvbox-material`
Expected: PASSA, e o `~/.config/swaylock/config` agora é arquivo de verdade, não symlink.

```bash
readlink ~/.config/swaylock/config || echo "arquivo real, como esperado"
grep -E '^(color|ring-ver-color)=' ~/.config/swaylock/config
```

Expected: `color=1d2021` e `ring-ver-color=7daea3` — sem `#`.

- [ ] **Step 7: Deixe na working tree e peça revisão**

```
feat(theme): generate the swaylock config from the active theme
```

---

### Task 4: ghostty

Entrega: o ghostty lê o tema de um `theme.conf` gerado.

**Files:**
- Modify: `theme/.local/bin/theme` (função `render_ghostty`)
- Modify: `ghostty/.config/ghostty/config`
- Modify: `tests/theme-test.sh`

**Interfaces:**
- Consumes: `load` da Task 1 (usa `ghostty_theme`, `ghostty_file`, `ghostty_extra`).
- Produces: `~/.config/ghostty/theme.conf`.

- [ ] **Step 1: Estenda o teste**

Some `"$HOME/.config/ghostty/theme.conf"` ao `GENERATED`, e dentro de `test_slug`, depois do loop:

```bash
    local want_bg got_bg
    want_bg=$(grep -oE '^background = #[0-9a-fA-F]{6}' <(ghostty +show-config 2>/dev/null) | head -1)
    [[ -n "$want_bg" ]] && ok "ghostty resolve um background ($want_bg)" || bad "ghostty não resolveu background"
```

- [ ] **Step 2: Rode e confirme que falha**

Run: `./tests/theme-test.sh gruvbox-material`
Expected: FALHOU — `~/.config/ghostty/theme.conf` faltando.

- [ ] **Step 3: Escreva `render_ghostty`**

O ghostty não usa os 16 papéis: ele usa o tema dele. Por isso não passa pelo `render` genérico. Em `theme/.local/bin/theme`:

```bash
# O ghostty tem paleta própria: ou aponta para um tema que ele já traz, ou para
# um arquivo de paleta que vendorizamos (caso dos jellybeans).
render_ghostty() {
    local dest="$CONFIG_DIR/ghostty/theme.conf" tmp
    tmp=$(mktemp)
    {
        printf '# Gerado por `theme set`. Não edite.\n'
        if [[ -n "${ghostty_theme:-}" ]]; then
            printf 'theme = %s\n' "$ghostty_theme"
        elif [[ -n "${ghostty_file:-}" ]]; then
            cat "$DATA_DIR/ghostty/$ghostty_file"
        else
            die "manifesto sem ghostty_theme nem ghostty_file"
        fi
        [[ -n "${ghostty_extra:-}" ]] && printf '%s\n' "$ghostty_extra"
    } > "$tmp"
    mkdir -p "$(dirname "$dest")"
    mv "$tmp" "$dest"
}
```

Chame `render_ghostty` no `cmd_set`, depois dos outros `render`.

- [ ] **Step 4: Aponte o config do ghostty**

Em `ghostty/.config/ghostty/config`, troque o bloco do cabeçalho (o comentário das variantes, a linha `theme = …` e a linha `background = #1d2021`) por:

```
# O tema vem do tema ativo da sessão (`theme set`), não daqui.
config-file = theme.conf
```

- [ ] **Step 5: Rode o teste e confira o ghostty**

```bash
./tests/theme-test.sh gruvbox-material
ghostty +show-config | grep -E '^(theme|background|foreground) '
```

Expected: `theme = Gruvbox Material Dark`, `background = #1d2021`, `foreground = #d4be98`.

- [ ] **Step 6: Deixe na working tree e peça revisão**

```
feat(theme): drive the ghostty theme from the active session theme
```

---

### Task 5: btop

Entrega: o btop segue o tema, usando o tema embutido quando existe e um gerado quando não existe.

**Files:**
- Create: `theme/.local/share/theme/templates/btop.theme`
- Modify: `theme/.local/bin/theme` (função `apply_btop`)
- Modify: `tests/theme-test.sh`

**Interfaces:**
- Consumes: `load`, `render`.
- Produces: `~/.config/btop/themes/current.theme` quando `btop_theme` está vazio; edita `color_theme` em `~/.config/btop/btop.conf` sempre.

- [ ] **Step 1: Escreva o teste**

Em `test_slug`, depois do loop de arquivos:

```bash
    local want got
    want=$(grep -oP '(?<=^btop_theme=")[^"]*' "$HOME/.local/share/theme/themes/$slug.theme" || true)
    [[ -z "$want" ]] && want=current
    got=$(grep -oP '(?<=^color_theme = ")[^"]*' "$HOME/.config/btop/btop.conf")
    [[ "$got" == "$want" ]] && ok "btop color_theme = $want" || bad "btop color_theme é '$got', esperava '$want'"
```

- [ ] **Step 2: Rode e confirme que falha**

Run: `./tests/theme-test.sh gruvbox-material`
Expected: FALHOU — nada escreve `color_theme` ainda (ele está fixo em `gruvbox_material_dark` por acaso; force a falha pondo `color_theme = "Default"` antes de rodar).

- [ ] **Step 3: Escreva `templates/btop.theme`**

38 chaves, todas a partir dos 16 papéis:

```
# Gerado por `theme set`. Não edite: mexa no manifesto do tema.
theme[main_bg]="@bg@"
theme[main_fg]="@fg@"
theme[title]="@fg@"
theme[hi_fg]="@red@"
theme[selected_bg]="@bg_hl@"
theme[selected_fg]="@fg@"
theme[inactive_fg]="@comment@"
theme[graph_text]="@fg_dim@"
theme[meter_bg]="@bg_hl@"
theme[proc_misc]="@green@"
theme[cpu_box]="@comment@"
theme[mem_box]="@comment@"
theme[net_box]="@comment@"
theme[proc_box]="@comment@"
theme[div_line]="@comment@"
theme[temp_start]="@green@"
theme[temp_mid]="@yellow@"
theme[temp_end]="@red@"
theme[cpu_start]="@green@"
theme[cpu_mid]="@cyan@"
theme[cpu_end]="@blue@"
theme[free_start]="@green@"
theme[free_mid]="@cyan@"
theme[free_end]="@blue@"
theme[cached_start]="@cyan@"
theme[cached_mid]="@blue@"
theme[cached_end]="@magenta@"
theme[available_start]="@yellow@"
theme[available_mid]="@orange@"
theme[available_end]="@red@"
theme[used_start]="@green@"
theme[used_mid]="@yellow@"
theme[used_end]="@red@"
theme[download_start]="@green@"
theme[download_mid]="@cyan@"
theme[download_end]="@blue@"
theme[upload_start]="@yellow@"
theme[upload_mid]="@orange@"
theme[upload_end]="@red@"
```

- [ ] **Step 4: Escreva `apply_btop`**

```bash
# O btop traz temas prontos para a maioria dos nossos slugs; quando não traz
# (jellybeans), geramos um a partir dos 16 papéis.
apply_btop() {
    local conf="$CONFIG_DIR/btop/btop.conf" name=${btop_theme:-}
    if [[ -z "$name" ]]; then
        render btop.theme "$CONFIG_DIR/btop/themes/current.theme"
        name=current
    fi
    [[ -f "$conf" ]] || return 0
    sed -i -E "s|^color_theme = \".*\"|color_theme = \"$name\"|" "$conf"
}
```

Chame `apply_btop` no `cmd_set`.

- [ ] **Step 5: Rode o teste nos dois caminhos**

```bash
./tests/theme-test.sh gruvbox-material     # caminho do tema pronto
# caminho gerado: zere o btop_theme temporariamente
sed -i 's/^btop_theme=.*/btop_theme=""/' ~/.local/share/theme/themes/gruvbox-material.theme
./tests/theme-test.sh gruvbox-material
tmux new-session -d -s btoptest -x 200 -y 50 btop && sleep 3
tmux capture-pane -p -e -t btoptest | grep -o '38;2;[0-9;]*' | sort | uniq -c | sort -rn | head -5
tmux kill-session -t btoptest
git -C ~/dotfiles checkout theme/.local/share/theme/themes/gruvbox-material.theme
```

Expected: nas duas rodadas o teste passa; a captura mostra `212;190;152` (`#d4be98`) entre as cores mais usadas.

- [ ] **Step 6: Deixe na working tree e peça revisão**

```
feat(theme): follow the active theme in btop
```

---

### Task 6: screenrec e o `theme.env`

Entrega: as cores do `slurp` saem do tema ativo.

**Files:**
- Modify: `theme/.local/bin/theme` (escreve `theme.env`)
- Modify: `screenrec/.local/bin/screenrec:50`
- Modify: `tests/theme-test.sh`

**Interfaces:**
- Produces: `~/.local/state/theme.env`, com os 16 papéis como `papel=#hex`, pronto para `source`.

- [ ] **Step 1: Escreva o teste**

```bash
    local env="$STATE/theme.env"
    assert_file "$env"
    ( set -a; . "$env"; set +a
      [[ "$bg_dark" =~ ^#[0-9a-fA-F]{6}$ ]] ) \
        && ok "theme.env define bg_dark" || bad "theme.env sem bg_dark utilizável"
```

- [ ] **Step 2: Rode e confirme que falha**

Expected: FALHOU — `theme.env` não existe.

- [ ] **Step 3: Escreva o `theme.env` no `cmd_set`**

```bash
    # Para scripts que precisam das cores em runtime (screenrec).
    { local role
      for role in "${ROLES[@]}"; do printf '%s=%s\n' "$role" "${!role}"; done
    } > "$STATE_DIR/theme.env"
```

- [ ] **Step 4: Faça o screenrec ler**

Em `screenrec/.local/bin/screenrec`, antes do uso do `slurp`, adicione:

```bash
# Cores do tema ativo; se faltar, o slurp usa o default dele.
THEME_ENV="${XDG_STATE_HOME:-$HOME/.local/state}/theme.env"
# shellcheck source=/dev/null
[[ -r "$THEME_ENV" ]] && source "$THEME_ENV"
```

e troque a linha 50 por:

```bash
            slurp -d -b "${bg_dark:-#1d2021}80" -c "${red:-#ea6962}ff" -s '#00000000' -w 2
```

- [ ] **Step 5: Rode o teste e o screenrec**

```bash
./tests/theme-test.sh gruvbox-material
bash -n screenrec/.local/bin/screenrec && echo "sintaxe OK"
```

Expected: teste passa; sintaxe OK. Teste manual: `$mod+Shift+r` abre o slurp com a borda vermelha do tema.

- [ ] **Step 6: Deixe na working tree e peça revisão**

```
feat(theme): take the screenrec selection colors from the active theme
```

---

### Task 7: Neovim

Entrega: o nvim abre no colorscheme do tema ativo, com os cinco plugins disponíveis.

**Files:**
- Modify: `theme/.local/bin/theme` (escreve `theme-nvim`)
- Modify: `nvim/.config/nvim/lua/plugins/colorscheme.lua` (reescrito)
- Modify: `nvim/.config/nvim/lua/config/lazy.lua:33`
- Modify: `nvim/.config/nvim/lazy-lock.json` (entram 4 plugins)
- Modify: `tests/theme-test.sh`

**Interfaces:**
- Produces: `~/.local/state/theme-nvim`, uma linha com o nome do colorscheme.

- [ ] **Step 1: Escreva o teste**

```bash
    local want got
    want=$(grep -oP '(?<=^nvim_colorscheme=")[^"]*' "$HOME/.local/share/theme/themes/$slug.theme")
    got=$(nvim --headless -c 'lua io.write(vim.g.colors_name or "?")' -c qa 2>&1 | tail -1)
    [[ "$got" == "$want" ]] && ok "nvim em $want" || bad "nvim em '$got', esperava '$want'"
```

- [ ] **Step 2: Rode e confirme que falha**

Expected: FALHOU — o nvim ainda abre em `gruvbox-material` fixo, e `theme-nvim` não existe.

- [ ] **Step 3: Escreva o `theme-nvim` no `cmd_set`**

```bash
    printf '%s\n' "${nvim_colorscheme:-gruvbox-material}" > "$STATE_DIR/theme-nvim"
```

- [ ] **Step 4: Reescreva o `colorscheme.lua`**

```lua
-- O tema ativo da sessão manda; quem escreve o arquivo é o script `theme`.
local function active()
  local path = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/theme-nvim"
  local f = io.open(path)
  if not f then
    return "gruvbox-material"
  end
  local name = f:read("l")
  f:close()
  return (name and name ~= "") and name or "gruvbox-material"
end

return {
  { "folke/tokyonight.nvim", lazy = true, opts = { style = "night" } },
  { "ellisonleao/gruvbox.nvim", lazy = true, opts = { contrast = "hard", terminal_colors = true } },
  {
    "sainnhe/gruvbox-material",
    lazy = true,
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
```

- [ ] **Step 5: Ajuste o fallback do lazy**

Em `nvim/.config/nvim/lua/config/lazy.lua:33`, troque para:

```lua
  install = { colorscheme = { "gruvbox-material", "habamax" } },
```

- [ ] **Step 6: Instale os plugins sem bagunçar o lockfile**

Nunca use `Lazy! sync` — ele atualiza todo mundo e polui o `lazy-lock.json`. Use:

```bash
nvim --headless "+Lazy! install" +qa
nvim --headless "+Lazy! clean" +qa
git -C ~/dotfiles diff --stat nvim/.config/nvim/lazy-lock.json
```

Expected: só linhas novas (`jellybeans.nvim`, `kanagawa.nvim`, `tokyonight.nvim`, `gruvbox.nvim`), nenhuma linha de plugin existente mudada. Se outras mudarem, rode `nvim --headless "+Lazy! restore" +qa`.

- [ ] **Step 7: Rode o teste**

Run: `./tests/theme-test.sh gruvbox-material`
Expected: `nvim em gruvbox-material`.

- [ ] **Step 8: Deixe na working tree e peça revisão**

```
feat(theme): pick the Neovim colorscheme from the active theme
```

---

### Task 8: O módulo na waybar

Entrega: ícone de paleta na barra; clique abre o menu, botão direito cicla.

**Files:**
- Modify: `theme/.local/bin/theme` (`cmd_waybar`, `cmd_menu`, `cmd_cycle`)
- Modify: `waybar/.config/waybar/config.jsonc` (módulo + posição)
- Modify: `waybar/.config/waybar/style.css` (cor do módulo)
- Modify: `tests/theme-test.sh`

**Interfaces:**
- Consumes: `cmd_list`, `cmd_get`, `cmd_set`.
- Produces: `theme waybar` imprime uma linha de JSON com `text`, `tooltip` e `class`.

- [ ] **Step 1: Escolha e confira o glyph**

O glyph mora **só no script bash** (`ICON=`), nunca no `config.jsonc` — o módulo
usa `"format": "{}"` e o texto vem do JSON que o script imprime. Então não há
caractere Nerd Font no JSON para escapar.

Veja qual dos dois candidatos renderiza na sua fonte:

```bash
printf 'nf-md-palette:        %b\nnf-md-palette_swatch: %b\n' '\Uf03d8' '\Uf0e0c'
```

Um vai aparecer como quadrado vazio. Anote o codepoint do que renderizou e use
`$'\U000f03d8'` (ou `$'\U000f0e0c'`) no script — **escape, nunca o caractere
cru**, que é o que já quebrou neste repo.

Depois de escrever o script, confirme os bytes que ele emite:

```bash
~/.local/bin/theme waybar | xxd -g1 | head -2
```

Expected: a sequência UTF-8 `f3 b0 8f 98` para `U+F03D8` (ou `f3 b0 b8 8c` para
`U+F0E0C`). Se vier `ef bf bd`, o escape virou caractere de substituição.

- [ ] **Step 2: Escreva o teste**

```bash
    local json
    json=$("$THEME" waybar)
    if printf '%s' "$json" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["class"]' 2>/dev/null; then
        ok "theme waybar devolve JSON com class"
    else
        bad "theme waybar não devolveu JSON válido: $json"
    fi
```

- [ ] **Step 3: Rode e confirme que falha**

Expected: FALHOU — `theme waybar` é subcomando desconhecido.

- [ ] **Step 4: Implemente os três subcomandos**

```bash
# Precisa bater com "signal" no módulo da waybar.
WAYBAR_SIGNAL=10

# Ícone de paleta (Nerd Font). Ver a nota sobre escapes no plano.
ICON=$'\U000f03d8'

label_of() {
    local slug=$1 label=""
    # shellcheck source=/dev/null
    label=$(source "$THEMES_DIR/$slug.theme"; printf '%s' "$label")
    printf '%s' "${label:-$slug}"
}

cmd_waybar() {
    local cur; cur=$(cmd_get)
    printf '{"text":"%s","tooltip":"Tema: %s","class":"%s"}\n' \
        "$ICON" "$(label_of "$cur")" "$cur"
}

cmd_cycle() {
    local cur next; cur=$(cmd_get)
    next=$(cmd_list | awk -v c="$cur" '{a[NR]=$0} END {for(i=1;i<=NR;i++) if(a[i]==c) {print a[i%NR+1]; exit} print a[1]}')
    cmd_set "$next"
}

cmd_menu() {
    local cur chosen; cur=$(cmd_get)
    chosen=$(cmd_list | while read -r s; do
                 [[ "$s" == "$cur" ]] && printf '● %s\n' "$(label_of "$s")" || printf '  %s\n' "$(label_of "$s")"
             done | wofi --dmenu --prompt 'Tema' --width 320 --height 300 \
                 --style "$CONFIG_DIR/wofi/style.css" 2>/dev/null) || return 0
    chosen=${chosen#● }; chosen=${chosen#  }
    local s
    for s in $(cmd_list); do
        [[ "$(label_of "$s")" == "$chosen" ]] && { cmd_set "$s"; return 0; }
    done
}
```

E no `case` do final:

```bash
    waybar) cmd_waybar ;;
    cycle)  cmd_cycle ;;
    menu)   cmd_menu ;;
```

Some `pkill -RTMIN+$WAYBAR_SIGNAL waybar >/dev/null 2>&1 || true` ao fim de `reload`.

- [ ] **Step 5: Ponha o módulo na barra**

Em `waybar/.config/waybar/config.jsonc`, no array `modules-right`, insira `"custom/theme"` imediatamente **antes** de `"custom/powerprofile"`. E adicione o bloco:

```jsonc
    // Trocador de tema. O "signal" tem que bater com WAYBAR_SIGNAL no script.
    "custom/theme": {
        "exec": "$HOME/.local/bin/theme waybar",
        "return-type": "json",
        "interval": 30,
        "signal": 10,
        "format": "{}",
        "on-click": "$HOME/.local/bin/theme menu",
        "on-click-right": "$HOME/.local/bin/theme cycle"
    },
```

Em `waybar/.config/waybar/style.css`, junto dos outros módulos:

```css
#custom-theme { color: @magenta; }
```

- [ ] **Step 6: Rode o teste e olhe a barra**

```bash
./tests/theme-test.sh gruvbox-material
pkill -SIGUSR2 waybar; sleep 1
grim -o eDP-1 /tmp/theme-task8.png
```

Expected: o teste passa e o print mostra o ícone de paleta à esquerda do perfil de energia. **Se aparecer um quadrado vazio, o glyph está errado** — volte ao Step 1.

- [ ] **Step 7: Teste o menu à mão**

Clique no ícone: o wofi tem que abrir com os temas disponíveis e o ativo marcado com `●`. Botão direito: cicla.

- [ ] **Step 8: Deixe na working tree e peça revisão**

```
feat(waybar): add a theme switcher module with a wofi picker
```

---

### Task 9: `theme doctor`, install-deps e README

Entrega: instalação limpa sobe com tema, e existe um comando que diz o que está faltando.

**Files:**
- Modify: `theme/.local/bin/theme` (`cmd_doctor`)
- Modify: `install-deps.sh`
- Modify: `README.md`

- [ ] **Step 1: Escreva `cmd_doctor`**

```bash
cmd_doctor() {
    local cur rc=0 f
    cur=$(cmd_get)
    printf 'tema ativo: %s\n\n' "$cur"
    for f in "$CONFIG_DIR/waybar/colors.css" "$CONFIG_DIR/sway/colors.conf" \
             "$CONFIG_DIR/swaync/colors.css" "$CONFIG_DIR/wofi/colors.css" \
             "$CONFIG_DIR/swaylock/config" "$CONFIG_DIR/ghostty/theme.conf" \
             "$STATE_DIR/theme.env" "$STATE_DIR/theme-nvim"; do
        if [[ -s "$f" ]]; then
            printf '  ok       %s\n' "$f"
        else
            printf '  FALTANDO %s\n' "$f"; rc=1
        fi
    done
    [[ $rc -eq 0 ]] || printf '\nrode: theme set %s\n' "$cur"
    return $rc
}
```

E `doctor) cmd_doctor ;;` no `case`.

- [ ] **Step 2: Teste o doctor nos dois estados**

```bash
theme doctor && echo "rc=0 como esperado"
mv ~/.config/waybar/colors.css /tmp/ && theme doctor; echo "rc=$?"
mv /tmp/colors.css ~/.config/waybar/ && theme doctor >/dev/null && echo "voltou ao normal"
```

Expected: `rc=0`, depois `FALTANDO …` com `rc=1`, depois normal.

- [ ] **Step 3: Ajuste o `install-deps.sh`**

Some `theme` à linha do `stow --no-folding` (em ordem alfabética, antes de `tmux`). E logo depois do bloco do stow:

```bash
    echo
    echo "==> Aplicando o tema padrão"
    "$HOME/.local/bin/theme" set gruvbox-material
```

- [ ] **Step 4: Documente no README**

Some a linha `| `theme` | temas da sessão e o trocador na barra |` na tabela de pacotes, tire a linha do `swaylock`, e crie uma seção `## Temas` explicando: os oito slugs, que `theme set` gera para fora do repo, que o ícone de paleta na barra abre o menu, e que ghostty e nvim já abertos só pegam o tema novo na próxima janela.

- [ ] **Step 5: Rode o teste inteiro e peça revisão**

```bash
bash -n install-deps.sh && ./install-deps.sh --print | tr ' ' '\n' | grep -c theme
./tests/theme-test.sh
```

```
feat(theme): add theme doctor, install hook and docs
```

---

### Task 10: Os outros sete temas

Entrega: os oito slugs funcionando.

**Files:**
- Create: sete manifestos em `theme/.local/share/theme/themes/`
- Create: `theme/.local/share/theme/ghostty/jellybeans-{muted,mono,hc}` (vendorizados)
- Create: `theme/.local/share/theme/ghostty/README.md` (origem dos arquivos)

**Interfaces:**
- Consumes: o formato de manifesto da Task 1.

- [ ] **Step 1: Extraia os dois que já existem**

```bash
git show a7d8821:waybar/.config/waybar/style.css | sed -n '7,22p'   # gruvbox-hard
git show e8f9b33:waybar/.config/waybar/style.css | sed -n '7,22p'   # tokyo-night
```

Escreva `gruvbox-hard.theme` e `tokyo-night.theme` com esses 16 valores. Complete os campos de app:

| slug | ghostty_theme | nvim_colorscheme | btop_theme |
| --- | --- | --- | --- |
| `gruvbox-hard` | `Gruvbox Dark Hard` | `gruvbox` | `gruvbox_dark` |
| `tokyo-night` | `TokyoNight Night` | `tokyonight-night` | `tokyo-night` |

- [ ] **Step 2: Teste os dois**

Run: `./tests/theme-test.sh gruvbox-hard tokyo-night`
Expected: tudo passa; `ghostty +show-config` dá `#1d2021` e `#1a1b26` respectivamente.

- [ ] **Step 3: Escreva os dois kanagawa**

Extraia a paleta base do tema do ghostty:

```bash
grep -E '^(background|foreground|palette = (1|2|3|4|5|6|8)=)' "/usr/share/ghostty/themes/Kanagawa Wave"
grep -E '^(background|foreground|palette = (1|2|3|4|5|6|8)=)' "/usr/share/ghostty/themes/Kanagawa Dragon"
```

Daí escolha à mão os três níveis de fundo e os dois de texto. Kanagawa Wave: `bg_dark #16161d`, `bg #1f1f28`, `bg_hl #2a2a37`, `fg #dcd7ba`, `fg_dim #c8c093`, `comment #727169`. Kanagawa Dragon: `bg_dark #12120f`, `bg #181616`, `bg_hl #282727`, `fg #c5c9c5`, `fg_dim #a6a69c`, `comment #737c73`. Os acentos saem do `palette`.

Campos de app: `ghostty_theme="Kanagawa Wave"` / `"Kanagawa Dragon"`, `nvim_colorscheme="kanagawa-wave"` / `"kanagawa-dragon"`, `btop_theme="kanagawa-wave"` / `"kanagawa-dragon"`.

- [ ] **Step 4: Crie o verificador de colisão e rode nos kanagawa**

A ordem dos módulos à direita da barra é `idle_inhibitor`(comment), `cpu`(green),
`memory`(magenta), `temperature`(teal), `custom-docker`(blue1), `backlight`(yellow),
`mic`(fg), `pulseaudio`(cyan), `custom-theme`(magenta), `custom-powerprofile`(blue),
`battery`(green). Dois vizinhos com a mesma cor viram uma mancha só.

Crie `tests/palette-collision.sh`:

```bash
#!/usr/bin/env bash
# Acusa papéis iguais em módulos vizinhos da barra.
#   ./tests/palette-collision.sh <slug> [<slug>...]
set -uo pipefail

THEMES="${XDG_DATA_HOME:-$HOME/.local/share}/theme/themes"
PAIRS=("comment green" "green magenta" "magenta teal" "teal blue1"
       "blue1 yellow" "yellow fg" "fg cyan" "cyan magenta"
       "magenta blue" "blue green")
fails=0

for slug in "$@"; do
    printf '\033[1m== %s\033[0m\n' "$slug"
    # shellcheck source=/dev/null
    ( source "$THEMES/$slug.theme"
      hit=0
      for pair in "${PAIRS[@]}"; do
          set -- $pair
          if [[ "${!1}" == "${!2}" ]]; then
              printf '  \033[31mCOLIDE\033[0m %s e %s = %s\n' "$1" "$2" "${!1}"
              hit=1
          fi
      done
      exit $hit ) || fails=$((fails + 1))
    [[ $? -eq 0 ]] && printf '  \033[32mok\033[0m sem vizinhos iguais\n'
done

exit $(( fails > 0 ))
```

```bash
chmod +x tests/palette-collision.sh
./tests/palette-collision.sh kanagawa-wave kanagawa-dragon
```

Expected: `sem vizinhos iguais` nos dois. Se colidir, escolha outro tom do
`palette` do ghostty para um dos dois papéis e rode de novo.

- [ ] **Step 5: Vendorize os arquivos de ghostty do jellybeans**

```bash
mkdir -p theme/.local/share/theme/ghostty
for v in muted mono hc; do
  curl -fsSL "https://raw.githubusercontent.com/WTFox/jellybeans.nvim/main/extras/ghostty/jellybeans-$v" \
    -o "theme/.local/share/theme/ghostty/jellybeans-$v"
done
head -3 theme/.local/share/theme/ghostty/jellybeans-muted
```

Expected: cada arquivo tem `background`, `foreground` e `palette = 0..15`.

Crie `theme/.local/share/theme/ghostty/README.md` dizendo que os três vieram de `WTFox/jellybeans.nvim`, pasta `extras/ghostty`, e em que data.

- [ ] **Step 6: Escreva os três manifestos jellybeans**

`ghostty_theme=""`, `ghostty_file="jellybeans-muted"` (e mono, hc), `btop_theme=""` (o btop não traz nenhum), `nvim_colorscheme="jellybeans-muted"` (e mono, hc). Os 16 papéis saem do `background`/`foreground`/`palette` de cada arquivo vendorizado, com os três níveis de fundo escolhidos à mão.

O `jellybeans-mono` é monocromático de propósito: ele **vai** colidir na checagem
abaixo. Nesse caso, use os dois acentos configuráveis do flavour (o `red` e o
`blue` do arquivo vendorizado) nos módulos que mais importam — `custom-docker` e
`custom-powerprofile` — e aceite o resto próximo do cinza.

```bash
./tests/palette-collision.sh jellybeans-muted jellybeans-mono jellybeans-hc
```

- [ ] **Step 7: Rode a bateria inteira**

Run: `./tests/theme-test.sh`
Expected: os oito passam, e a última seção confirma `git status limpo`.

- [ ] **Step 8: Olhe os oito na tela**

```bash
for s in $(theme list); do theme set "$s"; sleep 2; grim -o eDP-1 "/tmp/theme-$s.png"; done
theme set gruvbox-material
```

Abra os oito PNGs e confira a barra em cada um.

- [ ] **Step 9: Deixe na working tree e peça revisão**

```
feat(theme): add the remaining seven themes
```
