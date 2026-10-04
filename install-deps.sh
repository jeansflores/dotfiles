#!/usr/bin/env bash
#
# install-deps.sh — dependências destes dotfiles (Arch/CachyOS com COSMIC)
#
#   ./install-deps.sh            instala os pacotes e habilita os serviços
#   ./install-deps.sh --print    só imprime a linha do pacman, para colar num gist
#   ./install-deps.sh --stow     instala, habilita e aplica os pacotes stow
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Pacotes
#
# O desktop é o COSMIC "de fábrica" — painel, rede, bluetooth, notificações,
# bloqueio de tela e perfil de energia vêm dele, sem config neste repositório.
# Aqui ficam só as ferramentas que estes dotfiles configuram.
# ---------------------------------------------------------------------------
PKGS=(
    # Terminal e ferramentas
    alacritty
    btop
    starship                    #     prompt do shell
    wl-clipboard                #     área de transferência do Neovim no Wayland

    # Sistema
    power-profiles-daemon       #     backend dos perfis de energia do painel

    # Fontes
    ttf-jetbrains-mono-nerd     #     monoespaçada do terminal

    # Dotfiles
    stow

    # Gerenciador das ferramentas que não vêm do pacman (ver abaixo)
    mise
)

# Ferramentas que o mise instala, e não o pacman.
#
#   herdr       o pacote `herdr`
#   neovim      o pacote `nvim`
#   lazydocker  TUI do Docker
MISE_TOOLS=(herdr neovim lazydocker)

STOW_PKGS=(alacritty btop gitconfig herdr nvim starship)

print_line() {
    printf 'sudo pacman -S --needed %s\n' "${PKGS[*]}"
    printf 'mise use -g %s\n' "$(printf '%s@latest ' "${MISE_TOOLS[@]}")"
}

case "${1:-}" in
    --print|-p)
        print_line
        exit 0
        ;;
    --help|-h)
        sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
esac

command -v pacman >/dev/null || { echo "Este script é para Arch/CachyOS." >&2; exit 1; }

echo "==> Instalando pacotes"
sudo pacman -S --needed "${PKGS[@]}"

echo
echo "==> Instalando as ferramentas do mise"
if command -v mise >/dev/null; then
    for tool in "${MISE_TOOLS[@]}"; do
        mise use -g "$tool@latest"
    done
else
    echo "    (pulei: mise não encontrado)"
fi

echo
echo "==> Habilitando serviços do sistema"
# O applet de bluetooth e o de energia do painel do COSMIC dependem dos dois.
sudo systemctl enable --now power-profiles-daemon.service bluetooth.service

if [[ "${1:-}" == "--stow" ]]; then
    echo
    echo "==> Aplicando os pacotes stow"
    cd "$(dirname "$(readlink -f "$0")")"
    # --no-folding cria symlink por arquivo, nunca do diretório inteiro: assim
    # apps que escrevem no próprio diretório de config não sujam o repositório.
    stow --no-folding "${STOW_PKGS[@]}"
fi

cat <<'EOF'

==> Pronto.

Passos que continuam manuais:
  - abra o Neovim uma vez para o lazy.nvim instalar os plugins
  - crie no COSMIC o atalho do terminal com herdr (ver README, seção Atalhos)
EOF
