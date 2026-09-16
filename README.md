# dotfiles

Configuração de uma sessão **Sway** no CachyOS, com oito temas trocáveis pela barra.

Os arquivos são organizados em pacotes [GNU Stow](https://www.gnu.org/software/stow/):
cada diretório do primeiro nível replica a hierarquia a partir do `$HOME`.

## Instalação

```bash
git clone git@github.com:jeansflores/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-deps.sh --stow
```

O script instala os pacotes, habilita os serviços e aplica os symlinks. Para
apenas obter a lista de pacotes — útil para colar em outro lugar:

```bash
./install-deps.sh --print
```

Para aplicar (ou remover) um pacote isolado:

```bash
stow --no-folding waybar     # aplica
stow -D waybar               # remove
```

> O `--no-folding` cria um symlink por **arquivo**, nunca do diretório inteiro.
> Sem isso, o `~/.config/gtk-3.0` viraria um link para dentro do repositório e o
> seletor de arquivos do GTK passaria a gravar seus `bookmarks` aqui.

## Pacotes

| Pacote | O que cobre |
| --- | --- |
| `sway` | compositor, atalhos, autostarts, cores das bordas |
| `waybar` | barra superior e seu tema |
| `swaync` | daemon e centro de notificações |
| `ghostty` | terminal |
| `wofi` | tema do menu (usado pelo seletor de perfil de energia) |
| `gtk` | fonte, modo escuro e ícones das aplicações GTK 3 e 4 |
| `xdg-portal` | qual backend do xdg-desktop-portal atende cada função |
| `powerprofile` | seletor de perfil de energia e seu serviço systemd |
| `screenrec` | gravação de tela (wf-recorder) com indicador na barra |
| `nvim` | Neovim (LazyVim) |
| `btop` | monitor de sistema aberto pela barra |
| `theme` | os temas da sessão e o trocador na barra |
| `herdr` | herdr (workspace de terminais) |
| `tmux` | tmux |
| `gitconfig` | git |

## Temas

A sessão tem oito temas, trocáveis pelo ícone de paleta na barra — clique abre
um menu, botão direito cicla. Pela linha de comando:

```bash
theme list            # os slugs disponíveis
theme set kanagawa-dragon
theme cycle
theme doctor          # confere se algum arquivo gerado sumiu
```

| slug | |
| --- | --- |
| `gruvbox-material` | padrão |
| `gruvbox-hard` | |
| `tokyo-night` | |
| `jellybeans-muted` `jellybeans-mono` `jellybeans-hc` | |
| `kanagawa-wave` `kanagawa-dragon` | |

### Como funciona

Cada tema é um manifesto em `theme/.local/share/theme/themes/<slug>.theme`: os
16 papéis de cor escritos à mão, mais os nomes que o ghostty, o Neovim e o btop
usam para o mesmo tema. O `theme set` renderiza um template por app e escreve
**fora do repositório** — em `~/.config` e `~/.local/state`. É por isso que
trocar de tema nunca suja o `git status`.

```
themes/<slug>.theme  ─┐
templates/*          ─┴─► theme set ──► ~/.config/{waybar,sway,swaync,wofi,
                                          swaylock,ghostty,btop}/…
                                        ~/.local/state/theme{,.env,-nvim}
```

Adicionar um tema é escrever um manifesto — mais o arquivo de paleta do
ghostty, quando o ghostty não traz aquele tema (é o caso dos três jellybeans,
vendorizados de `WTFox/jellybeans.nvim`).

O `tmux` e o `herdr` não têm cor própria: o tmux usa nomes (`blue`,
`brightblack`) e o herdr está em `theme.name = "terminal"`. Os dois seguem o
ghostty sozinhos.

### O que troca na hora e o que não troca

Sway, waybar e swaync trocam ao vivo. Wofi, swaylock e btop pegam o tema novo
na próxima vez que abrem. **Ghostty e Neovim já abertos ficam com a paleta
antiga** — no ghostty, `ctrl+shift+,` recarrega; no Neovim, só a próxima
instância.

### Quando algo sai sem cor

Se a waybar ou o wofi subirem **sem estilo nenhum** e sem mensagem de erro, é um
arquivo gerado faltando: o GTK descarta um `@import` quebrado em silêncio.
`theme doctor` diz qual, e `theme set <slug>` reconstrói.

### Fonte e ícones

- **Monoespaçada:** JetBrainsMono Nerd Font
- **Interface:** Noto Sans
- **Ícones:** Papirus-Dark
- **GTK:** Adwaita em modo escuro

O modo escuro do GTK3 vem de `gtk-application-prefer-dark-theme`, e **não** de um
tema chamado `Adwaita-dark` — esse nome só existe no GTK4. Apontar o
`gtk-theme-name` para ele faz o GTK3 não encontrar o tema e cair no claro. O GTK
não acompanha a troca de tema: fica sempre no escuro do Adwaita.

## Atalhos

`Mod` é a tecla Super. Só o que foge do padrão do Sway está listado; navegação
por `Mod+hjkl`, workspaces por `Mod+1..0` e o modo `resize` seguem o default.

| Atalho | Ação |
| --- | --- |
| `Mod+Return` | terminal (ghostty) |
| `Mod+Alt+Return` | terminal com herdr (sessão persistente) |
| `Mod+d` | lançador (wmenu-run) |
| `Mod+Shift+q` | fecha a janela |
| `Mod+Shift+c` | recarrega o Sway |
| `Mod+Shift+e` | encerra a sessão |
| `Mod+Ctrl+l` | bloqueia a tela |
| `Mod+n` | abre o centro de notificações |
| `Mod+Shift+n` | alterna o "não perturbe" |
| `Print` | seleciona uma região e copia para a área de transferência |
| `Shift+Print` | tela inteira em `~/Pictures/Screenshots` |
| `Mod+Print` | janela em foco, para a área de transferência |
| `Mod+Shift+r` | grava uma região da tela; de novo, para |
| `Mod+Ctrl+r` | grava a tela inteira; `Mod+Shift+r` para |

As teclas de mídia e de brilho do notebook funcionam mesmo com a tela
bloqueada (`--locked`).

## Barra

Da esquerda para a direita: workspaces, título da janela, relógio ao centro e,
à direita, indicador de gravação (só enquanto grava), inibidor de suspensão,
CPU, memória, temperatura, Docker, brilho, microfone, volume, tema, perfil de
energia, bateria, bandeja e notificações.

Rede e bluetooth **não** têm módulo próprio: ficam na bandeja, a cargo do
`nm-applet` e do `blueman-applet`, subidos por `exec` no config do Sway. Sem
display manager, o `graphical-session.target` do `systemd --user` nunca fica
ativo nesta sessão, então o `xdg-desktop-autostart.target` (que dependeria
dele) nunca sobe o `nm-applet.desktop` sozinho — daí o `exec` explícito para
os dois.

O sensor de temperatura é apontado por `hwmon-path-abs` no diretório do
dispositivo, e não por `/sys/class/hwmon/hwmonN`, cuja numeração muda entre
boots.

## Docker

O ícone segue o serviço: apagado (cinza) quando o `docker.service` está
parado, baleia acesa com a contagem de containers em execução quando está
ativo. Clique abre o `lazydocker` num terminal — igual ao `btop` que abre ao
clicar na CPU/RAM.

```bash
dockerstatus waybar   # JSON consumido pelo módulo custom/docker
```

Não depende de sudo: o usuário já está no grupo `docker`, e `systemctl
is-active`/`docker ps` não exigem privilégio para consultar. O `lazydocker`
vem do `mise` (não é pacote destes dotfiles).

## Gravação de tela

`Mod+Shift+r` abre o `slurp` para escolher uma região e começa a gravar;
`Mod+Ctrl+r` grava a tela inteira. Enquanto grava, um ponto vermelho piscando
com o tempo decorrido aparece na ponta direita da barra — clique nele, ou
`Mod+Shift+r` de novo, para parar. O arquivo vai para `~/Videos/Screencasts`
com timestamp no nome, como os screenshots, e o caminho chega por notificação.

```bash
screenrec toggle [region|screen]  # inicia ou para
screenrec start "0,0 1280x720"    # geometria explícita, útil em script
screenrec stop
screenrec status                  # "recording <s>" ou "idle"
```

Codifica por GPU (`h264_vaapi` no Radeon, quase zero CPU). Se a VA-API falhar
ao subir, cai sozinho para `libx264` e a notificação avisa qual foi usado. O
`wl-screenrec` seria a alternativa mais leve, mas só existe no AUR; o
`wf-recorder` está no repositório oficial.

## Perfil de energia

O `power-profiles-daemon` não guarda o perfil entre reinicializações: ele sempre
volta em `balanced`. O pacote `powerprofile` resolve isso.

O ícone na barra segue o perfil ativo — `󰾆` economia (verde), `󰾅` equilibrado
(azul), `󰓅` desempenho (laranja). Clique abre um menu wofi; botão direito cicla.

```bash
powerprofile get             # perfil ativo
powerprofile set performance # aplica e memoriza
powerprofile cycle           # avança para o próximo
powerprofile menu            # menu wofi
```

O serviço de usuário `power-profile.service` faz duas coisas: reaplica o perfil
memorizado no login e observa o D-Bus para memorizar qualquer troca posterior —
inclusive as que não passam pelo script. O estado fica em
`~/.local/state/power-profile`.

O script conversa com o daemon por `busctl`, e não pelo `powerprofilesctl`.
Além de dispensar dependência de runtime, isso evita um problema real deste
host: o `mise` coloca seu Python à frente do `/usr/bin` no `PATH`, e o
`powerprofilesctl` — que usa `#!/usr/bin/env python3` — acaba rodando num
interpretador sem o PyGObject, falhando com `ModuleNotFoundError: No module
named 'gi'` mesmo com o `python-gobject` instalado.

## Notas da sessão

- **Não há display manager.** O login é por TTY e o Sway sobe manualmente.
- **`exec` no config do Sway não roda no `swaymsg reload`**, apenas no login. Ao
  adicionar um autostart, suba o processo à mão ou reinicie a sessão.
- O **agente polkit** (`polkit-gnome`) é o que permite ao `pkexec` e a
  aplicações como o blueman pedirem senha em janela. Sem ele, o `pkexec` tenta o
  prompt textual e falha por não haver TTY.
- O locale `pt_BR` **não** está gerado; por isso o relógio usa data numérica.
