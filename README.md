# dotfiles

Configuração das ferramentas de terminal que uso no CachyOS, toda na paleta
**Jellybeans HC**. O desktop é o **COSMIC** de fábrica: painel, rede,
bluetooth, notificações, bloqueio de tela e perfil de energia vêm dele, sem
config aqui.

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
> `install-deps.sh --stow` usa `--no-folding` e aplica só os 5 pacotes de verdade.

O script faz, nesta ordem: instala os pacotes do pacman, instala pelo `mise` as
ferramentas que não existem no pacman, habilita os serviços e aplica os symlinks.

Para só ver o que seria instalado:

```bash
./install-deps.sh --print
```

### O que vem de onde

| | vem de | por quê |
| --- | --- | --- |
| alacritty, btop, stow, mise, … | `pacman` | estão em `PKGS` no script |
| **herdr**, **neovim**, **lazydocker** | `mise` | não existem nos repositórios; estão em `MISE_TOOLS` |

O `mise` instala os binários em `~/.local/share/mise/`, e os **shims não estão
no `PATH` de processos subidos pelo COSMIC** — atalhos de teclado e lançadores
não passam por shell de login. Por isso o atalho do herdr usa o caminho
absoluto do shim. Se uma dessas ferramentas funcionar no terminal mas não por
um atalho, é aqui que se olha.

### Depois de instalar

1. **Abra o Neovim uma vez.** O lazy.nvim instala os plugins no primeiro
   arranque, incluindo o colorscheme.
2. **Crie o atalho do herdr** no COSMIC (ver [Atalhos](#atalhos)).

Para aplicar (ou remover) um pacote isolado:

```bash
stow --no-folding nvim     # aplica
stow -D nvim               # remove
```

> O `--no-folding` cria um symlink por **arquivo**, nunca do diretório inteiro.
> Sem isso, um app que grava no próprio diretório de config passaria a gravar
> dentro do repositório.

## Pacotes

| Pacote | O que cobre |
| --- | --- |
| `alacritty` | terminal |
| `herdr` | multiplexador de agentes |
| `nvim` | Neovim (LazyVim) |
| `btop` | monitor de sistema |
| `gitconfig` | git |

## Atalhos

O COSMIC guarda os atalhos em `~/.config/cosmic`, fora deste repositório. O
único personalizado é o do terminal com herdr, criado em **Configurações →
Teclado → Atalhos de teclado → Atalhos personalizados**:

| Atalho | Comando |
| --- | --- |
| `Super+Alt+Return` | `alacritty -e /home/jean/.local/share/mise/shims/herdr` |

## Paleta

Uma paleta só, **Jellybeans HC** (de `WTFox/jellybeans.nvim`), escrita à mão em
cada app — sem script gerador, sem arquivo fora do repositório.

| arquivo | o que tem |
| --- | --- |
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

### herdr

O tema `terminal` do herdr deriva dos 16 ANSI do alacritty, mas põe o *texto*
sobre a *cor de acento* — em paleta escura os dois são tons claros e o
contraste cai para 1.4-2.8:1. A tabela `[theme.custom]` troca os fundos pelos
níveis escuros da paleta e o texto volta a sentar sobre escuro.

O herdr às vezes reescreve o próprio `config.toml`. Se o `git status` acusar
mudança nele, foi isso.

### Fonte

A monoespaçada do terminal é a **JetBrainsMono Nerd Font**. O alacritty não faz
ligaduras de fonte: `->` e `!=` aparecem como caracteres separados.
