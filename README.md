# dotfiles

Configuração das ferramentas de terminal que uso no CachyOS, toda na paleta
**Catppuccin Mocha**. O desktop é o **COSMIC** de fábrica: painel, rede,
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

Uma paleta só, **Catppuccin Mocha**, nos arquivos oficiais de cada port do
[Catppuccin](https://github.com/catppuccin) copiados sem mudança — sem arquivo
fora do repositório.

| arquivo | o que tem |
| --- | --- |
| `alacritty/.config/alacritty/alacritty.toml` | `catppuccin-mocha.toml` de [catppuccin/alacritty](https://github.com/catppuccin/alacritty), colado no fim |
| `kitty/.config/kitty/current-theme.conf` | `mocha.conf` de [catppuccin/kitty](https://github.com/catppuccin/kitty), incluído pelo `kitty.conf` |
| `btop/.config/btop/themes/catppuccin_mocha.theme` | de [catppuccin/btop](https://github.com/catppuccin/btop) |
| `herdr/.config/herdr/config.toml` | tema `terminal` + fundos escuros em `[theme.custom]` |
| `nvim/…/plugins/colorscheme.lua` | `catppuccin-mocha` ([catppuccin/nvim](https://github.com/catppuccin/nvim)), sem overrides |

| papel | hex | | papel | hex |
| --- | --- | --- | --- | --- |
| `base` (fundo) | `#1e1e2e` | | `red` | `#f38ba8` |
| `mantle` | `#181825` | | `maroon` | `#eba0ac` |
| `crust` | `#11111b` | | `peach` | `#fab387` |
| `surface0` | `#313244` | | `yellow` | `#f9e2af` |
| `surface1` | `#45475a` | | `green` | `#a6e3a1` |
| `surface2` | `#585b70` | | `teal` | `#94e2d5` |
| `overlay2` | `#9399b2` | | `sky` | `#89dceb` |
| `subtext1` | `#bac2de` | | `blue` | `#89b4fa` |
| `subtext0` | `#a6adc8` | | `lavender` | `#b4befe` |
| `text` | `#cdd6f4` | | `mauve` | `#cba6f7` |
| `rosewater` (cursor) | `#f5e0dc` | | `pink` | `#f5c2e7` |

Nos terminais, o `normal` e o `bright` de cada ANSI são a mesma cor, como no
port oficial; só `black` (`surface1`/`surface2`) e `white` (`subtext1`/`subtext0`)
mudam. O `mauve` é o acento do herdr.

### Papéis

Os terminais só mostram os 16 ANSI. Quem decide *qual cor vai em qual token* é
o catppuccin/nvim, sem nenhum override. Para Go e TypeScript, isso dá:

| token | cor |
| --- | --- |
| keywords (`func`, `type`, `struct`, `import`, `return`, `const`) | mauve |
| condicionais (`if`, `else`, `switch`), em itálico no nvim | mauve |
| tipos (`Shape`, `fmt.State`, interfaces, classes) | yellow |
| tipos builtin (`string`, `int`, `error`, `number`) | mauve |
| nome de pacote/módulo (`fmt`, `package main`), em itálico | yellow |
| funções e métodos | blue |
| builtins (`len`, `make`, `append`) | peach |
| variáveis | text |
| parâmetros | maroon |
| campos e propriedades | lavender |
| números, booleanos, constantes, `nil` | peach |
| strings | green |
| escapes em string, regex | pink |
| `%s` e outros verbos de formato | teal |
| operadores (`:=`, `*`, `==`) | sky |
| pontuação (`,`, `.`, `;`, `:` de tipo) | overlay2 |
| `this`/`self`, `console` | red |
| comentários, em itálico | overlay2 |
| colchetes, por nível de aninhamento | red, yellow, blue, peach, green, mauve |

Os tokens semânticos do LSP usam os grupos `@lsp.type.*` do catppuccin. Os
níveis de colchete são o `rainbow-delimiters.nvim` com as cores da integração
do catppuccin.

O colorscheme é `catppuccin-mocha`, e não `catppuccin`: o Neovim 0.12 traz um
`colors/catppuccin.vim` próprio no runtime, que é achado antes do plugin e
pinta as variáveis de `flamingo`.

### VSCode

O VSCode usa o tema **Catppuccin Mocha** da loja (extensão
`Catppuccin.catppuccin-vsc`), sem nada neste repositório: a extensão e o
`workbench.colorTheme` chegam pelo Settings Sync.

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
