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

# assert_colors_defined <style.css> <colors.css>
assert_colors_defined() {
    local style=$1 colors=$2 missing=""
    [[ -r "$style" && -r "$colors" ]] || { bad "não consegui ler $style ou $colors"; return; }
    local name
    while read -r name; do
        grep -q "^@define-color $name " "$colors" || missing+=" @$name"
    done < <(grep -oE '@[a-z_][a-z0-9_]*' "$style" \
             | grep -vE '^@(import|define-color|media|keyframes|charset)$' \
             | sed 's/^@//' | sort -u)
    if [[ -z "$missing" ]]; then
        ok "todo @nome de $(basename "$(dirname "$style")")/style.css está definido"
    else
        bad "$(basename "$(dirname "$style")")/style.css usa cor não definida:$missing"
    fi
}

GENERATED=(
    "$HOME/.config/waybar/colors.css"
    "$HOME/.config/sway/colors.conf"
    "$HOME/.config/swaync/colors.css"
    "$HOME/.config/wofi/colors.css"
    "$HOME/.config/swaylock/config"
    "$HOME/.config/ghostty/theme.conf"
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

    # Todo @nome usado no style.css tem que estar definido no colors.css gerado.
    # Se faltar, o GTK descarta a regra calado e o app sobe sem estilo.
    assert_colors_defined "$HOME/.config/waybar/style.css" "$HOME/.config/waybar/colors.css"
    assert_colors_defined "$HOME/.config/swaync/style.css" "$HOME/.config/swaync/colors.css"
    assert_colors_defined "$HOME/.config/wofi/style.css"   "$HOME/.config/wofi/colors.css"

    # O fundo que o ghostty resolve tem que ser um dos fundos do tema. Se não
    # for, o terminal está numa cor que o resto da sessão não usa.
    local got want_dark want_bg
    got=$(ghostty +show-config 2>/dev/null | grep -m1 '^background = ' | awk '{print tolower($3)}')
    want_dark=$(grep -m1 '^bg_dark=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d= -f2)
    want_bg=$(grep -m1 '^bg=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d= -f2)
    if [[ -z "$got" ]]; then
        bad "ghostty não resolveu nenhum background"
    elif [[ "$got" == "$want_dark" || "$got" == "$want_bg" ]]; then
        ok "ghostty em $got, que é um fundo do tema"
    else
        bad "ghostty em $got, mas o tema usa $want_dark / $want_bg"
    fi
}

slugs=("$@")
[[ ${#slugs[@]} -eq 0 ]] && mapfile -t slugs < <("$THEME" list 2>/dev/null)

# Fotografa o repo antes: o que interessa é se TROCAR DE TEMA muda algo, não se
# há trabalho em andamento não commitado.
before_status=$(git -C "$REPO" status --porcelain)

for s in "${slugs[@]}"; do test_slug "$s"; done

printf '\n\033[1m== erros ==\033[0m\n'

WAYBAR_CSS="$HOME/.config/waybar/colors.css"

# Slug desconhecido: sai com 2 e não toca em nada.
before=$(cat "$WAYBAR_CSS" 2>/dev/null)
"$THEME" set nao-existe >/dev/null 2>&1
rc=$?
[[ $rc -eq 2 ]] && ok "slug desconhecido sai com 2" || bad "slug desconhecido saiu com $rc, esperava 2"
after=$(cat "$WAYBAR_CSS" 2>/dev/null)
[[ "$before" == "$after" ]] && ok "slug desconhecido não mexeu nos arquivos" || bad "slug desconhecido alterou colors.css"

# Manifesto sem um papel: aborta antes de escrever.
tmp_manifest="$HOME/.local/share/theme/themes/zz-teste.theme"
grep -v '^blue=' "$HOME/.local/share/theme/themes/gruvbox-material.theme" > "$tmp_manifest"
before=$(cat "$WAYBAR_CSS" 2>/dev/null)
"$THEME" set zz-teste >/dev/null 2>&1
rc=$?
[[ $rc -ne 0 ]] && ok "manifesto incompleto falha (rc=$rc)" || bad "manifesto sem 'blue' passou"
after=$(cat "$WAYBAR_CSS" 2>/dev/null)
[[ "$before" == "$after" ]] && ok "manifesto incompleto não escreveu nada" || bad "manifesto incompleto sujou colors.css"
rm -f "$tmp_manifest"

printf '\n\033[1m== repositório ==\033[0m\n'
after_status=$(git -C "$REPO" status --porcelain)
if [[ "$before_status" == "$after_status" ]]; then
    ok "trocar de tema não mexeu no repositório"
else
    bad "trocar de tema mexeu no repositório:"
    diff <(printf '%s\n' "$before_status") <(printf '%s\n' "$after_status") | sed 's/^/        /'
fi

printf '\n'
if [[ $fails -eq 0 ]]; then printf '\033[32mtudo passou\033[0m\n'; else printf '\033[31m%s falha(s)\033[0m\n' "$fails"; fi
exit $(( fails > 0 ))
