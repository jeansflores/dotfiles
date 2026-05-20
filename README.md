# dotfiles

Configurações gerenciadas com [GNU Stow](https://www.gnu.org/software/stow/).

## Estrutura

```
dotfiles/
├── alacritty/   → ~/.config/alacritty/
├── autostart/   → ~/.config/autostart/
├── ghostty/     → ~/.config/ghostty/
├── gitconfig/   → ~/
├── i3/          → ~/.config/i3/
├── nvim/        → ~/.config/nvim/
├── polybar/     → ~/.config/polybar/
├── scripts/     → ~/.local/bin/
└── tmux/        → ~/
```

---

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
  power-profiles-daemon \
  kernel-tools \
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
stow i3 polybar alacritty autostart scripts nvim gitconfig tmux
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

### 6. Ativar power-profiles-daemon

```bash
sudo systemctl enable --now power-profiles-daemon
```

### 7. Serviço de controle térmico (Ryzen 7 7735HS)

Limita EPP e frequência máxima para reduzir aquecimento:

```bash
sudo cp ~/dotfiles/scripts/thermal-control.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now thermal-control
```

### 8. Toggle de turbo boost na polybar (sudoers)

```bash
echo "SEU_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/devices/system/cpu/cpufreq/boost" | \
  sudo tee /etc/sudoers.d/boost-toggle
```

### 9. Hotplug de monitor (udev)

```bash
echo 'ACTION=="change", SUBSYSTEM=="drm", RUN+="/home/SEU_USER/.local/bin/monitor-hotplug"' | \
  sudo tee /etc/udev/rules.d/95-monitor-hotplug.rules
sudo udevadm control --reload-rules
```

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
| `Ctrl+Win+Backspace` | Toggle espelho (mirror ↔ estendido) |
| `Ctrl+Win+Delete` | Toggle monitor externo (externo only ↔ estendido) |

---

## Polybar

| Módulo | Interação |
|--------|-----------|
| `CPU` / `RAM` | Clique esquerdo → abre btop |
| `VOL` | Clique esquerdo → abre pavucontrol |
| `VOL` | Clique direito → muta/desmuta |
| `VOL` | Scroll → volume ±5% |
| `PWR-SAVE` / `BALANCED` / `PERF` | Clique esquerdo → cicla perfil de energia |
| `TURBO ON` / `TURBO OFF` | Clique esquerdo → toggle turbo boost da CPU |
| `⌨ US` / `⌨ BR` | Clique esquerdo → alterna layout US intl ↔ BR ABNT2 |

---

## Gerenciamento de energia e térmico

### Power Profiles

| Perfil | Quando usar |
|--------|-------------|
| `PWR-SAVE` | Bateria curta, reunião, leitura |
| `BALANCED` | Uso geral, dev leve — padrão recomendado |
| `PERF` | Build pesado, Docker, compilação |

### Turbo Boost

| Estado | Comportamento |
|--------|--------------|
| `TURBO OFF` | CPU limitada a 3.4GHz — ventoinha quieta, dev confortável |
| `TURBO ON` | CPU até 4.8GHz — máxima performance, mais calor |

**Combinações recomendadas:**

| Situação | Perfil | Turbo |
|----------|--------|-------|
| Dev no cabo, uso geral | `BALANCED` | OFF |
| Build pesado / Docker | `BALANCED` ou `PERF` | ON |
| Bateria, sem build | `PWR-SAVE` | OFF |
| Apresentação / reunião | `PWR-SAVE` | OFF |

---

## Monitor externo

O script `monitor-manager` gerencia os modos via xrandr:

| Comando | Ação |
|---------|------|
| `monitor-manager extend` | Estendido (laptop + externo) |
| `monitor-manager external` | Somente externo (laptop pode ser fechado) |
| `monitor-manager mirror` | Espelho |
| `monitor-manager auto` | Detecta e aplica estendido se externo conectado |

Ao conectar o HDMI o modo estendido é ativado automaticamente via udev.

---

## Hardware (Laptop atual)

- **CPU**: AMD Ryzen 7 7735HS
- **GPU**: AMD Radeon 680M (Rembrandt / RDNA2)
- **Driver GPU**: radeonsi (Mesa open-source) — não instalar driver proprietário
- **Touchpad**: FTCS0038:00 2808:0106 — tap-to-click ativado via xinput no i3 config
- **Teclado**: US International (dead keys) padrão, alternável para BR ABNT2 pela polybar
- **Monitor externo**: HDMI-A-0 (3440x1440)
