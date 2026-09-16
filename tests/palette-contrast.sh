#!/usr/bin/env bash
# Guarda de contraste da paleta. Um tema novo não pode nascer com destaque de
# seleção invisível nem com texto ilegível em cima dele.
#
#   ./tests/palette-contrast.sh [<slug>...]
set -uo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
THEMES="$REPO/theme/.local/share/theme/themes"

SEP_MIN=1.5   # bg_sel contra bg_dark: abaixo disso o olho não separa
LEG_MIN=4.5   # fg sobre bg_sel: mínimo WCAG AA para texto normal

slugs=("$@")
[[ ${#slugs[@]} -eq 0 ]] && mapfile -t slugs < <(cd "$THEMES" && ls -1 ./*.theme | sed 's|.*/||;s|\.theme$||')

python3 - "$THEMES" "$SEP_MIN" "$LEG_MIN" "${slugs[@]}" <<'PY'
import sys, pathlib, re
themes, sep_min, leg_min, *slugs = sys.argv[1:]
sep_min, leg_min = float(sep_min), float(leg_min)

def lum(h):
    h = h.lstrip('#')
    c = [int(h[i:i+2], 16)/255 for i in (0, 2, 4)]
    c = [x/12.92 if x <= 0.03928 else ((x+0.055)/1.055)**2.4 for x in c]
    return 0.2126*c[0] + 0.7152*c[1] + 0.0722*c[2]

def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

fails = 0
print(f"{'tema':<20} {'separação':>10} {'legibilidade':>13}")
print("-" * 46)
for slug in sorted(slugs):
    t = dict(re.findall(r'^(\w+)=#?([0-9a-fA-F]{6})$',
                        (pathlib.Path(themes)/f"{slug}.theme").read_text(), re.M))
    sep = ratio('#'+t['bg_dark'], '#'+t['bg_sel'])
    leg = ratio('#'+t['fg'], '#'+t['bg_sel'])
    bad = sep < sep_min or leg < leg_min
    mark = '\033[31m FALHOU\033[0m' if bad else '\033[32m ok\033[0m'
    print(f"{slug:<20} {sep:>10.2f} {leg:>13.2f}{mark}")
    fails += bad

print()
if fails:
    print(f"\033[31m{fails} tema(s) fora do alvo\033[0m "
          f"(separação >= {sep_min}, legibilidade >= {leg_min})")
else:
    print(f"\033[32mtodos dentro do alvo\033[0m "
          f"(separação >= {sep_min}, legibilidade >= {leg_min})")
sys.exit(1 if fails else 0)
PY
