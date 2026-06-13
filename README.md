# dotfiles

Configurações gerenciadas com [GNU Stow](https://www.gnu.org/software/stow/) no CachyOS (Arch).

## Estrutura

```
dotfiles/
├── fish/       → ~/.config/fish/config.fish
├── gitconfig/  → ~/.gitconfig
├── i3/         → ~/.config/i3/
├── nvim/       → ~/.config/nvim/
├── polybar/    → ~/.config/polybar/
└── redshift/   → ~/.config/redshift.conf
```

---

## Instalação em uma máquina nova

### 1. Clonar o repositório

```bash
git clone <url-do-repo> ~/dotfiles
cd ~/dotfiles
```

### 2. Instalar dependências do sistema

```bash
sudo pacman -S \
  stow \
  i3-wm i3lock-color \
  polybar \
  alacritty \
  rofi \
  fish \
  feh \
  picom \
  dunst \
  dex \
  polkit-gnome \
  brightnessctl \
  pamixer \
  xob \
  btop \
  pavucontrol \
  power-profiles-daemon \
  thunar gvfs thunar-volman udisks2 \
  awesome-terminal-fonts ttf-hack \
  redshift
```

### 3. Ativar serviços

```bash
sudo systemctl enable --now power-profiles-daemon
```

### 4. Instalar mise e ferramentas de desenvolvimento

```bash
# instalar mise
curl https://mise.run | sh
echo 'mise activate fish | source' >> ~/.config/fish/config.fish

# ferramentas (ajuste conforme necessário)
mise install
```

O arquivo `~/.config/mise/config.toml` define as versões — inclui: `neovim`, `zellij`, `node`, `python`, `go`, `lazygit`, `lazydocker`.

### 5. Aplicar dotfiles

```bash
cd ~/dotfiles
stow fish gitconfig i3 nvim polybar redshift
```

---

## Atalhos i3

| Atalho | Ação |
|--------|------|
| `Win+Enter` | Terminal (alacritty) |
| `Win+Alt+Enter` | Terminal com zellij |
| `Win+D` | Lançador (rofi) |
| `Win+Q` | Fechar janela |
| `Win+F` | Fullscreen |
| `Win+L` | Bloquear tela |
| `Win+Shift+P` | Calculadora |
| `Win+Shift+C` | Reload i3 |
| `Win+Shift+R` | Restart i3 |
| `Win+Shift+E` | Sair do i3 |
| `Win+R` | Modo resize |
| `Win+H / V / T` | Split horizontal / vertical / toggle |
| `Win+S / W / E` | Layout stacking / tabbed / split |
| `Win+Shift+Space` | Toggle floating |
| `Win+1..0` | Trocar workspace |
| `Win+Shift+1..0` | Mover janela para workspace |
| `Fn+Brilho ↑↓` | Brilho ±5% (com barra OSD) |
| `Fn+Volume ↑↓` | Volume ±3% (com barra OSD) |
| `Fn+Mute` | Mudo |

---

## Polybar

Barra superior com os módulos:

`workspaces` · `data` · `CPU` · `RAM` · `BAT` · `VOL` · `perfil de energia` · `tray`

| Módulo | Clique esquerdo | Clique direito | Scroll |
|--------|----------------|----------------|--------|
| CPU / RAM | abre btop | — | — |
| VOL | abre pavucontrol | muta/desmuta | ±5% |
| PWR-SAVE / BALANCED / PERF | cicla perfil | — | — |

---

## Hardware

- **CPU**: AMD Ryzen 7 7735HS
- **GPU**: AMD Radeon 680M — driver `amdgpu` (Mesa, não instalar proprietário)
- **Display**: eDP 1920x1200
