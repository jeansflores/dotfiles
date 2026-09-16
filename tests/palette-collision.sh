#!/usr/bin/env bash
# Acusa papéis iguais em módulos VIZINHOS da barra — dois vizinhos na mesma cor
# viram uma mancha só.
#   ./tests/palette-collision.sh <slug> [<slug>...]
#   ./tests/palette-collision.sh              (todos)
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
THEMES="$REPO/theme/.local/share/theme/themes"

# A ordem real dos módulos à direita, de fora para dentro.
PAIRS=("comment green" "green magenta" "magenta teal" "teal blue1"
       "blue1 yellow" "yellow fg" "fg cyan" "cyan magenta"
       "magenta blue" "blue green")

fails=0
slugs=("$@")
if [[ ${#slugs[@]} -eq 0 ]]; then
    mapfile -t slugs < <(cd "$THEMES" && ls -1 *.theme 2>/dev/null | sed 's/\.theme$//')
fi

for slug in "${slugs[@]}"; do
    printf '\033[1m== %s\033[0m\n' "$slug"
    if [[ ! -r "$THEMES/$slug.theme" ]]; then
        printf '  \033[31mFALHOU\033[0m manifesto não encontrado\n'; fails=$((fails + 1)); continue
    fi
    hits=$(
        # shellcheck source=/dev/null
        source "$THEMES/$slug.theme"
        for pair in "${PAIRS[@]}"; do
            set -- $pair
            [[ "${!1}" == "${!2}" ]] && printf '  %s e %s = %s\n' "$1" "$2" "${!1}"
        done
    )
    if [[ -z "$hits" ]]; then
        printf '  \033[32mok\033[0m sem vizinhos iguais\n'
    else
        printf '\033[31m  COLIDE:\033[0m\n%s\n' "$hits"; fails=$((fails + 1))
    fi
done

printf '\n'
[[ $fails -eq 0 ]] && printf '\033[32mnenhuma colisão\033[0m\n' || printf '\033[31m%s tema(s) com colisão\033[0m\n' "$fails"
exit $(( fails > 0 ))
