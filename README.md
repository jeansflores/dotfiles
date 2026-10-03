# dotfiles

Configuração de uma sessão **Sway** no CachyOS, toda na paleta **Jellybeans HC**.

Os arquivos são organizados em pacotes [GNU Stow](https://www.gnu.org/software/stow/):
cada diretório do primeiro nível replica a hierarquia a partir do `$HOME`.

## Instalação

```bash
git clone git@github.com:jeansflores/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-deps.sh --stow
```

Numa máquina zerada, isto é o último passo de um roteiro maior — chave SSH, yay,
Chrome, Slack, grupo do Docker e o acerto de teclado no GRUB estão num
[gist à parte](https://gist.github.com/jeansflores/77b80c867a276d5c27a9bfbb401f9903).
O que precisa casar entre os dois é só isto:

> **Não use `stow *`.** Num `$HOME` limpo, o stow sem `--no-folding` transforma o
> `~/.config` inteiro num link para dentro deste repositório, e o `*` ainda
> tentaria stowar o `README.md` e o próprio `install-deps.sh`. O
> `install-deps.sh --stow` usa `--no-folding` e aplica só os 14 pacotes de verdade.

O script faz, nesta ordem: instala os pacotes do pacman, instala pelo `mise` as
ferramentas que não existem no pacman, habilita os serviços e aplica os symlinks.

Para só ver o que seria instalado:

```bash
./install-deps.sh --print
```

### O que vem de onde

Nem tudo é pacote do pacman, e a diferença importa numa máquina nova:

| | vem de | por quê |
| --- | --- | --- |
| sway, waybar, wofi, swaync, swaylock, alacritty, btop, … | `pacman` | estão em `PKGS` no script |
| **herdr**, **neovim**, **lazydocker** | `mise` | não existem nos repositórios; estão em `MISE_TOOLS` |

O `mise` instala os binários em `~/.local/share/mise/`, e os **shims não estão
no `PATH` de processos subidos pelo Sway** — a waybar não tem shell de login. Por
isso tudo que chama essas ferramentas fora de um terminal usa caminho absoluto
do shim: o `Mod+Alt+Return` do herdr e o clique do Docker na barra. Se um dia
uma dessas chamadas parar de funcionar "só pela barra", é aqui que se olha.

### Depois de instalar

Duas coisas continuam manuais:

1. **Reinicie a sessão do Sway.** O `exec` do config só roda no login, não no
   `swaymsg reload` — os autostarts (polkit, swaync, swayidle) não sobem sozinhos.
2. **Abra o Neovim uma vez.** O lazy.nvim instala os plugins no primeiro
   arranque, incluindo o colorscheme.

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
| `sway` | compositor, atalhos, autostarts, paleta e cores das bordas |
| `waybar` | barra superior e seu tema |
| `swaync` | daemon e centro de notificações |
| `wofi` | menus (perfil de energia) |
| `swaylock` | tela de bloqueio |
| `alacritty` | terminal |
| `herdr` | multiplexador de agentes (`Mod+Alt+Return`) |
| `gtk` | fonte, modo escuro e ícones das aplicações GTK 3 e 4 |
| `xdg-portal` | qual backend do xdg-desktop-portal atende cada função |
| `powerprofile` | seletor de perfil de energia e seu serviço systemd |
| `screenrec` | gravação de tela (wf-recorder) com indicador na barra |
| `nvim` | Neovim (LazyVim) |
| `btop` | monitor de sistema aberto pela barra |
| `gitconfig` | git |

## Paleta

Uma paleta só, **Jellybeans HC** (de `WTFox/jellybeans.nvim`), escrita à mão em
cada app — sem script gerador, sem arquivo fora do repositório.

| arquivo | o que tem |
| --- | --- |
| `sway/.config/sway/config` | bloco `set $bg …` no topo; bordas, fundo e lançador usam as variáveis |
| `waybar/.config/waybar/colors.css` | `@define-color`, importado pelo `style.css` |
| `swaync/.config/swaync/colors.css` | idem |
| `wofi/.config/wofi/style.css` | cores literais (ver abaixo) |
| `swaylock/.config/swaylock/config` | cores sem `#`, como o swaylock exige |
| `alacritty/.config/alacritty/alacritty.toml` | os 16 ANSI + fundo, texto, cursor |
| `herdr/.config/herdr/config.toml` | tema `terminal` + fundos escuros em `[theme.custom]` |
| `btop/.config/btop/themes/jellybeans-hc.theme` | tema do btop |
| `nvim/…/plugins/colorscheme.lua` | `jellybeans-hc` |

| papel | hex | | papel | hex |
| --- | --- | --- | --- | --- |
| `bg_dark` | `#000000` | | `blue` | `#98b0e0` |
| `bg` | `#060606` | | `cyan` | `#aad4f8` |
| `bg_hl` | `#1a1a1a` | | `magenta` | `#d8c8ff` |
| `bg_sel` | `#363636` | | `green` | `#8cd468` |
| `fg` | `#f8f8f0` | | `yellow` | `#ffe080` |
| `fg_dim` | `#c8c8c0` | | `orange` | `#ffc060` |
| `comment` | `#909090` | | `red` | `#ff5050` |
| | | | `teal` | `#78a0b8` |

### Levando para o i3

O config do sway foi escrito para ser portável: a paleta é um bloco de
`set $nome valor` no topo, e as linhas `client.*`, `font`, `default_border`,
`smart_borders` e `gaps` têm a mesma sintaxe no i3 (gaps desde a 4.22). Copie a
paleta, as variáveis e a seção **Aparência**; o que é só do sway está marcado
nos comentários (`output * bg`, `titlebar_padding`, e o `wmenu-run` — que tem a
linha equivalente de `dmenu_run` comentada ao lado).

### herdr

O tema `terminal` do herdr deriva dos 16 ANSI do alacritty, mas põe o *texto*
sobre a *cor de acento* — em paleta escura os dois são tons claros e o
contraste cai para 1.4-2.8:1. A tabela `[theme.custom]` troca os fundos pelos
níveis escuros da paleta e o texto volta a sentar sobre escuro.

O herdr às vezes reescreve o próprio `config.toml`. Se o `git status` acusar
mudança nele, foi isso.

### Quando algo sai sem cor

O **wofi** carrega o CSS por *conteúdo*, não por caminho — então um
`@import "colors.css"` resolve contra o diretório de trabalho de quem lançou o
wofi, e não contra `~/.config/wofi`. Lançado pela barra, o import falha calado e
o menu sai **transparente**. Por isso o `style.css` dele tem as cores literais.

### Fonte e ícones

- **Monoespaçada:** JetBrainsMono Nerd Font
- **Interface:** Noto Sans
- **Ícones:** Papirus-Dark
- **GTK:** Adwaita em modo escuro

O modo escuro do GTK3 vem de `gtk-application-prefer-dark-theme`, e **não** de um
tema chamado `Adwaita-dark` — esse nome só existe no GTK4. Apontar o
`gtk-theme-name` para ele faz o GTK3 não encontrar o tema e cair no claro.

O alacritty não faz ligaduras de fonte (o ghostty fazia): `->` e `!=` aparecem
como caracteres separados.

## Atalhos

`Mod` é a tecla Super. Só o que foge do padrão do Sway está listado; navegação
por `Mod+hjkl`, workspaces por `Mod+1..0` e o modo `resize` seguem o default.

| Atalho | Ação |
| --- | --- |
| `Mod+Return` | terminal (alacritty) |
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
CPU, memória, temperatura, Docker, brilho, volume e bateria — os que mostram
valor — e, por último, os que são só ícone: perfil de energia (colado na
bateria), microfone, bandeja e notificações.

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
- **O `PATH` do Sway não tem o mise.** Processos subidos pelo Sway (waybar,
  swaync, e o que a barra lança no clique) não passam por shell de login. Quem
  chama `herdr`, `nvim` ou `lazydocker` de lá precisa do caminho absoluto do
  shim, `~/.local/share/mise/shims/<tool>`.
