# dotfiles

Configurações gerenciadas com [GNU Stow](https://www.gnu.org/software/stow/).

## Estrutura

```
dotfiles/
├── alacritty/   → ~/.config/alacritty/
├── ghostty/     → ~/.config/ghostty/
├── gitconfig/   → ~/
├── i3/          → ~/.config/i3/
├── nvim/        → ~/.config/nvim/
├── polybar/     → ~/.config/polybar/
└── tmux/        → ~/
```

## Instalação em uma máquina nova

### 1. Clonar o repositório

```bash
git clone <url-do-repo> ~/dotfiles
cd ~/dotfiles
```

### 2. Instalar dependências

```bash
sudo dnf install -y \
  i3 i3status i3lock \
  polybar \
  alacritty \
  zellij \
  neovim \
  btop \
  flameshot \
  pavucontrol \
  fontawesome-fonts \
  brightnessctl \
  dex-autostart \
  xss-lock \
  nm-applet \
  xorg-x11-apps \
  stow
```

### 3. Instalar IosevkaTerm Nerd Font

```bash
mkdir -p ~/.local/share/fonts/iosevka
bash -c 'for url in "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Iosevka.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/IosevkaTerm.tar.xz"; do f=$(basename "$url"); curl -fL -o "/tmp/$f" "$url" && tar -xf "/tmp/$f" -C ~/.local/share/fonts/iosevka/; done && fc-cache -fv'
```

### 4. Aplicar dotfiles com stow

```bash
cd ~/dotfiles
stow i3 polybar alacritty nvim gitconfig tmux
```

> Para remover os symlinks: `stow -D <pacote>`

### 5. Configuração do Xorg (AMD TearFree)

```bash
echo 'Section "Device"
    Identifier "AMD Radeon 680M"
    Driver     "amdgpu"
    Option     "TearFree" "true"
EndSection' | sudo tee /etc/X11/xorg.conf.d/20-amdgpu.conf
```

Reiniciar a sessão X para aplicar.

---

## Atalhos i3

| Atalho | Ação |
|--------|------|
| `Win+Return` | Abre Alacritty |
| `Win+Alt+Return` | Abre Alacritty com Zellij |
| `Win+Shift+S` | Screenshot (Flameshot) |
| `Win+D` | Lançador dmenu |
| `Win+Shift+Q` | Fecha janela |
| `Win+Shift+R` | Restart i3 |
| `Win+Shift+C` | Reload i3 |
| `Win+Shift+E` | Sair do i3 |
| `Win+F` | Fullscreen |
| `Win+R` | Modo resize |
| `Win+1..0` | Trocar workspace |
| `Win+Shift+1..0` | Mover janela para workspace |

## Polybar

| Elemento | Interação |
|----------|-----------|
| CPU / RAM | Clique esquerdo → btop |
| VOL | Clique esquerdo → pavucontrol |
| VOL | Clique direito → muta/desmuta |
| VOL | Scroll → volume ±5% |
| ⌨ Layout | Clique esquerdo → alterna US ↔ BR (ABNT2) |

## Hardware (Laptop atual)

- **GPU**: AMD Radeon 680M (Rembrandt / RDNA2)
- **Driver**: radeonsi (Mesa open-source) — não instalar driver proprietário
- **Touchpad**: FTCS0038:00 2808:0106 — tap-to-click ativado via xinput no i3 config
- **Teclado**: US International (dead keys) padrão, alternável para BR ABNT2 pela polybar
