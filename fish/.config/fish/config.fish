#
# ~/.config/fish/config.fish
#
# Diferente do bash, o fish lê este arquivo em TODA execução, inclusive não
# interativa (`fish -c`, comando remoto via ssh). O que precisa valer nesses
# casos fica fora do `status is-interactive`. Os arquivos de conf.d/ rodam
# antes deste.

# Shims do mise no PATH mesmo em sessão não interativa: o app do Herdr Mobile
# conecta por ssh rodando um comando, e o `mise activate` lá embaixo nunca roda
# nesse caminho. Sem isto ele não acha o binário `herdr`.
fish_add_path -g --path $HOME/.local/share/mise/shims $HOME/.local/bin

set -gx PYENV_ROOT $HOME/.pyenv
test -d $PYENV_ROOT/bin; and fish_add_path -g --path $PYENV_ROOT/bin

if status is-interactive
    # Sem a mensagem de boas-vindas. `ls` e `grep` já vêm com --color=auto
    # nas funções embutidas do fish, então os aliases do bash não fazem falta.
    set -g fish_greeting

    starship init fish | source
    mise activate fish | source

    # Depois do mise, para os shims do pyenv ficarem na frente no PATH,
    # como era no bash.
    if command -q pyenv
        pyenv init - fish | source
        pyenv virtualenv-init - fish | source
    end
end
