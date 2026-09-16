#!/usr/bin/env bash
#
# install-deps.sh — dependências do setup Sway deste repositório (Arch/CachyOS)
#
#   ./install-deps.sh            instala os pacotes e habilita os serviços
#   ./install-deps.sh --print    só imprime a linha do pacman, para colar num gist
#   ./install-deps.sh --stow     instala, habilita e aplica os pacotes stow
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Pacotes
#
# Os marcados com (+) foram adicionados por cima do que a ISO do CachyOS com
# Sway já traz. Os demais vêm na ISO e estão listados só para o script
# funcionar numa instalação limpa — o --needed pula o que já existe.
# ---------------------------------------------------------------------------
PKGS=(
    # Compositor e sessão
    sway
    swayidle                    # (+) bloqueio e desligamento de tela por inatividade
    swaylock                    # (+) tela de bloqueio
    polkit-gnome                # (+) agente de autenticação; sem ele pkexec não abre janela
    xdg-desktop-portal
    xdg-desktop-portal-wlr      #     captura e compartilhamento de tela
    xdg-desktop-portal-gtk      # (+) seletor de arquivos, tema, abrir URI

    # Barra, menu e notificações
    waybar
    wofi
    swaync                      # (+) daemon de notificações + centro de notificações

    # Terminal
    ghostty

    # Utilitários de sessão
    brightnessctl               # (+) controle de brilho pelas teclas de função
    playerctl
    grim                        #     screenshot
    slurp                       #     seleção de região
    wf-recorder                 # (+) gravação de tela (script screenrec)
    wl-clipboard
    jq                          #     usado no bind de screenshot da janela em foco
    btop                        # (+) monitor aberto pelo clique na CPU/RAM da barra

    # Áudio e bluetooth
    pavucontrol
    blueman                     #     GUI de bluetooth, chamada pelo ícone do tray

    # Rede
    networkmanager
    network-manager-applet      # (+) nm-applet: ícone de tray com o menu de redes
    nm-connection-editor        # (+) janela GTK de conexões

    # Energia
    power-profiles-daemon       #     backend dos perfis power-saver/balanced/performance

    # Fontes
    ttf-jetbrains-mono-nerd     # (+) monoespaçada do terminal
    ttf-nerd-fonts-symbols      #     glyphs de ícone da waybar
    noto-fonts                  #     interface
    noto-fonts-emoji

    # Tema
    papirus-icon-theme          # (+) ícones (variante Papirus-Dark)

    # Dotfiles
    stow
)

print_line() {
    printf 'sudo pacman -S --needed %s\n' "${PKGS[*]}"
}

case "${1:-}" in
    --print|-p)
        print_line
        exit 0
        ;;
    --help|-h)
        sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
esac

command -v pacman >/dev/null || { echo "Este script é para Arch/CachyOS." >&2; exit 1; }

echo "==> Instalando pacotes"
sudo pacman -S --needed "${PKGS[@]}"

echo
echo "==> Habilitando serviços do sistema"
sudo systemctl enable --now power-profiles-daemon.service bluetooth.service

if [[ "${1:-}" == "--stow" ]]; then
    echo
    echo "==> Aplicando os pacotes stow"
    cd "$(dirname "$(readlink -f "$0")")"
    # --no-folding cria symlink por arquivo, nunca do diretório inteiro: assim
    # apps que escrevem em ~/.config/gtk-3.0 e afins não sujam o repositório.
    stow --no-folding btop gitconfig ghostty gtk herdr nvim powerprofile screenrec \
                      sway swaylock swaync tmux wofi waybar xdg-portal
fi

echo
echo "==> Habilitando o serviço de usuário do perfil de energia"
if [[ -e "$HOME/.config/systemd/user/power-profile.service" ]]; then
    systemctl --user daemon-reload
    systemctl --user enable --now power-profile.service
else
    echo "    (pulei: rode o stow antes, ou use ./install-deps.sh --stow)"
fi

cat <<'EOF'

==> Pronto.

Passos que continuam manuais:
  - reinicie a sessão do Sway para os autostarts subirem (polkit, swaync, swayidle)
  - o nm-applet e o blueman-applet sobem sozinhos via xdg-desktop-autostart.target
EOF
