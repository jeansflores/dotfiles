#!/bin/bash
set -e

echo "==> Atualizando sistema..."
sudo pacman -Syu --noconfirm

echo "==> Instalando ZSh..."
sudo pacman -Syu --noconfirm git base-devel zsh curl

echo "==> Instalando oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "==> Configurando YAY..."
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si
cd - && rm -rf /tmp/yay

echo "==> Configurando rede..."
sudo pacman -S --noconfirm networkmanager network-manager-applet
sudo systemctl enable NetworkManager

echo "==> Ferramentas de energia e brilho..."
sudo pacman -S --noconfirm acpi acpilight brightnessctl tlp
sudo systemctl enable tlp

echo "==> Instalando interface e UX..."
sudo pacman -S --noconfirm rofi feh picom lxappearance dunst polkit-gnome

echo "==> Instalando barra e ícones..."
sudo pacman -S --noconfirm papirus-icon-theme noto-fonts ttf-jetbrains-mono

echo "==> Instalando apps úteis..."
sudo pacman -S --noconfirm thunar flameshot htop blueman cbatticon

echo "==> Desativando beep do sistema..."
sudo rmmod pcspkr 2>/dev/null || true
echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf >/dev/null
echo "set bell-style none" >> ~/.inputrc

echo "==> Finalizado!"
source ~/.zshrc
