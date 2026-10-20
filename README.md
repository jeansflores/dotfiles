# dotfiles

Configuração das ferramentas de terminal que uso no CachyOS, toda na paleta
**Gruvbox Dark**. O desktop é o **COSMIC** de fábrica: painel, rede,
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
> `install-deps.sh --stow` usa `--no-folding` e aplica só os 8 pacotes de verdade.

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

1. **Troque o shell de login para o fish:** `chsh -s /usr/bin/fish` (pede a
   senha; vale a partir do próximo login).
2. **Abra o Neovim uma vez.** O lazy.nvim instala os plugins no primeiro
   arranque, incluindo o colorscheme.
3. **Crie o atalho do herdr** no COSMIC (ver [Atalhos](#atalhos)).

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
| `kitty` | terminal em teste, espelho do `alacritty` (mesma fonte, padding e paleta) |
| `herdr` | multiplexador de agentes |
| `nvim` | Neovim (LazyVim) |
| `btop` | monitor de sistema |
| `fish` | shell de login: mise, starship, pyenv e as envs do `api_gv3` |
| `starship` | prompt do shell (ícone de branch no tamanho cheio) |
| `gitconfig` | git |

## fish

O fish lê o `config.fish` em toda execução, inclusive não interativa (`fish -c`,
comando remoto via ssh), ao contrário do `.bashrc`. Por isso os shims do mise
entram no `PATH` antes do `status is-interactive`: é o que deixa o app do Herdr
Mobile achar o `herdr` ao conectar por ssh.

As envs do `api_gv3` vêm de `~/work/api_gv3/.env` (fora do git), em
`conf.d/api_gv3.fish`. O `.env` tem sintaxe de shell POSIX, então quem o
interpreta é o bash, e o fish só importa as variáveis que ele define.

O `fish_variables` (variáveis universais) fica fora do repositório: o fish
reescreve esse arquivo sozinho.

## Atalhos

O COSMIC guarda os atalhos em `~/.config/cosmic`, fora deste repositório. Dá
para criá-los em **Configurações → Teclado → Atalhos de teclado → Atalhos
personalizados**, ou editando direto
`~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom` — o COSMIC
lê o arquivo na hora.

| Atalho | Comando |
| --- | --- |
| `Super+Return` | `kitty` |
| `Super+Alt+Return` | `kitty /home/jean/.local/share/mise/shims/herdr` |

O terminal padrão do sistema fica em `system_actions`, no mesmo diretório
(`Terminal: "kitty"`). No alacritty, o comando do herdr leva `-e`:
`alacritty -e /home/jean/.local/share/mise/shims/herdr`.

## Paleta

Uma paleta só, **Gruvbox Dark** (a original de [morhetz](https://github.com/morhetz/gruvbox),
variante *dark* de contraste médio, com os hex de
[terminalcolors.com](https://terminalcolors.com/themes/gruvbox/dark/)), escrita
à mão em cada app — sem script gerador, sem arquivo fora do repositório.

| arquivo | o que tem |
| --- | --- |
| `alacritty/.config/alacritty/alacritty.toml` | os 16 ANSI + fundo, texto, cursor, seleção |
| `kitty/.config/kitty/current-theme.conf` | os mesmos hex do alacritty, incluído pelo `kitty.conf` |
| `herdr/.config/herdr/config.toml` | tema `terminal` + fundos escuros em `[theme.custom]` |
| `btop/.config/btop/themes/gruvbox-dark.theme` | tema do btop |
| `nvim/…/plugins/colorscheme.lua` | `gruvbox` (plugin `ellisonleao/gruvbox.nvim`, contraste médio) |

| papel | normal | bright | | papel | hex |
| --- | --- | --- | --- | --- | --- |
| `black` | `#282828` | `#928374` | | `bg` | `#282828` |
| `red` | `#cc241d` | `#fb4934` | | `fg` | `#ebdbb2` |
| `green` | `#98971a` | `#b8bb26` | | `bg1` | `#3c3836` |
| `yellow` | `#d79921` | `#fabd2f` | | `bg2` | `#504945` |
| `blue` | `#458588` | `#83a598` | | `bg3` | `#665c54` |
| `magenta` | `#b16286` | `#d3869b` | | `gray` | `#928374` |
| `cyan` | `#689d6a` | `#8ec07c` | | `orange` | `#fe8019` |
| `white` | `#a89984` | `#ebdbb2` | | | |

O `orange` não está nos 16 ANSI; é o acento do herdr. O cursor e a seleção
invertem fundo e texto (`#ebdbb2` sobre `#282828`), como no terminalcolors.

### herdr

O tema `terminal` do herdr deriva dos 16 ANSI do terminal, mas põe o *texto*
sobre a *cor de acento* — em paleta escura os dois são tons claros e o
contraste cai para 1.4-2.8:1. A tabela `[theme.custom]` troca os fundos pelos
níveis escuros da paleta e o texto volta a sentar sobre escuro.

O herdr às vezes reescreve o próprio `config.toml`. Se o `git status` acusar
mudança nele, foi isso.

### Fonte

A monoespaçada do terminal é a **IosevkaTerm Nerd Font**: estreita, cabe mais
código por linha e funciona bem com o nvim em splits. Use a variante sem
"Mono" — na "Mono" os ícones são espremidos em uma célula e ficam minúsculos.

Mesmo assim, os ícones ficam menores que no ghostty: o alacritty desenha cada
glyph no tamanho que a fonte define, sem ampliá-lo para preencher a célula. Ele
também não faz ligaduras: `->` e `!=` aparecem como caracteres separados.
