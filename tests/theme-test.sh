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
    "$HOME/.config/wofi/style.css"
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

    # O theme.env precisa ser fonte válida para scripts (screenrec).
    local env_file="$STATE/theme.env"
    assert_file "$env_file"
    if ( set -a; . "$env_file"; set +a; [[ "${bg_dark:-}" =~ ^#[0-9a-fA-F]{6}$ && "${red:-}" =~ ^#[0-9a-fA-F]{6}$ ]] ); then
        ok "theme.env dá source e define bg_dark e red"
    else
        bad "theme.env não é fonte válida ou falta papel"
    fi

    local want_dark want_bg
    want_dark=$(grep -m1 '^bg_dark=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d= -f2)
    want_bg=$(grep -m1 '^bg=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d= -f2)

    # O módulo da barra precisa devolver JSON válido, com o glyph certo.
    local json
    json=$("$THEME" waybar 2>/dev/null)
    if printf '%s' "$json" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["class"] and d["text"] and d["tooltip"]' 2>/dev/null; then
        ok "theme waybar devolve JSON completo"
    else
        bad "theme waybar não devolveu JSON válido: $json"
    fi
    if printf '%s' "$json" | grep -q $'\U000f03d8'; then
        ok "o glyph de paleta chegou inteiro no JSON"
    else
        bad "glyph errado ou virou caractere de substituição"
    fi

    # O nvim tem que abrir na VARIANTE certa. Comparar vim.g.colors_name com o
    # manifesto não serve: o kanagawa reporta "kanagawa" tanto no wave quanto no
    # dragon. O que distingue variante é o fundo que ele resolve, então exigimos
    # as duas coisas — o nome pedido tem que começar pelo colors_name, e o fundo
    # tem que ser um dos fundos do tema.
    local want_nvim got_nvim got_nvim_bg
    want_nvim=$(grep -m1 '^nvim_colorscheme=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d'"' -f2)
    read -r got_nvim got_nvim_bg < <(nvim --headless -c 'lua local n=vim.api.nvim_get_hl(0,{name="Normal"}) io.write((vim.g.colors_name or "?").." #"..string.format("%06x", n.bg or 0))' -c qa 2>&1 | tail -1 | tr -d '\r')
    if [[ "$want_nvim" != "$got_nvim"* ]]; then
        bad "nvim em '$got_nvim', que não corresponde a '$want_nvim'"
    elif [[ "$got_nvim_bg" == "$want_dark" || "$got_nvim_bg" == "$want_bg" ]]; then
        ok "nvim em $want_nvim, fundo $got_nvim_bg"
    else
        bad "nvim em $want_nvim mas com fundo $got_nvim_bg; o tema usa $want_dark / $want_bg"
    fi

    # O btop tem que estar no tema que o manifesto pediu — ou em "current",
    # quando o manifesto deixa btop_theme vazio e nós geramos o arquivo.
    local want_btop got_btop
    want_btop=$(grep -m1 '^btop_theme=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d= -f2 | tr -d '"')
    [[ -z "$want_btop" ]] && want_btop=current
    got_btop=$(grep -m1 '^color_theme = ' "$HOME/.config/btop/btop.conf" | cut -d'"' -f2)
    [[ "$got_btop" == "$want_btop" ]] && ok "btop em $want_btop" || bad "btop em '$got_btop', esperava '$want_btop'"

    # O herdr tem que estar no tema que o manifesto pediu, e o próprio herdr
    # tem que aceitar o config — ele valida e reclama de nome inválido.
    local want_herdr got_herdr
    want_herdr=$(grep -m1 '^herdr_theme=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d'"' -f2)
    got_herdr=$(grep -m1 '^name = ' "$HOME/.config/herdr/config.toml" 2>/dev/null | cut -d'"' -f2)
    [[ "$got_herdr" == "$want_herdr" ]] && ok "herdr em $want_herdr" || bad "herdr em '$got_herdr', esperava '$want_herdr'"
    if herdr config check 2>&1 | grep -qiE 'unknown theme|unknown config key'; then
        bad "o herdr rejeitou algo: $(herdr config check 2>&1 | tail -1)"
    else
        ok "herdr config check aceita tema e chaves de cor"
    fi
    # As cores do [theme.custom] têm que ser as do manifesto. É o que conserta o
    # contraste: os fundos do herdr passam a ser os nossos três níveis escuros.
    local hc_sel hc_acc
    hc_sel=$(grep -m1 '^selection_bg' "$HOME/.config/herdr/config.toml" | cut -d'"' -f2)
    hc_acc=$(grep -m1 '^accent' "$HOME/.config/herdr/config.toml" | cut -d'"' -f2)
    local m_hl m_blue
    m_hl=$(grep -m1 '^bg_hl=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d= -f2)
    m_blue=$(grep -m1 '^blue=' "$HOME/.local/share/theme/themes/$slug.theme" | cut -d= -f2)
    if [[ "$hc_sel" == "$m_hl" && "$hc_acc" == "$m_blue" ]]; then
        ok "herdr theme.custom com as cores do tema (selection $hc_sel, accent $hc_acc)"
    else
        bad "herdr theme.custom divergente: selection $hc_sel (esperava $m_hl), accent $hc_acc (esperava $m_blue)"
    fi

    # O style.css do wofi NÃO pode ter referência @nome nenhuma — nem @import,
    # nem @cor. O wofi carrega CSS por conteúdo, sem caminho base, então um
    # @import relativo resolve contra o diretório de trabalho de quem lançou o
    # wofi e falha calado: as cores ficam indefinidas, o GTK descarta as regras
    # e a janela sai transparente. Cor literal é a única forma segura aqui.
    # Os comentários do arquivo falam sobre @import de propósito, então eles
    # saem antes da checagem — o que importa são as regras.
    local refs
    refs=$(sed 's|/\*|\n&|g' "$HOME/.config/wofi/style.css" 2>/dev/null \
           | sed '/\/\*/,/\*\//d' \
           | grep -oE '@[a-z_-]+' | sort -u | tr '\n' ' ')
    if [[ -z "$refs" ]]; then
        ok "wofi/style.css só tem cor literal, sem @import nem @cor"
    else
        bad "wofi/style.css tem referência @ que o wofi não resolve: $refs"
    fi

    # O fundo que o ghostty resolve tem que ser um dos fundos do tema. Se não
    # for, o terminal está numa cor que o resto da sessão não usa.
    local got
    got=$(ghostty +show-config 2>/dev/null | grep -m1 '^background = ' | awk '{print tolower($3)}')
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
