# --- api_gv3: envs do projeto ----------------------------------------------
# O settings.py lê os.environ direto (não carrega dotenv), então as vars
# precisam estar exportadas no ambiente. Em vez de duplicar as senhas aqui,
# este bloco lê o .env do projeto (modo 600, fora do git): fonte única de
# verdade, e este arquivo continua sem segredos.
#
# O .env usa sintaxe de shell POSIX (aspas, espaços), então quem interpreta é o
# próprio bash; daqui só se importam as variáveis que o arquivo define.
#
# Para rodar 100% local, sem buscar segredos no env server por gRPC
# (settings.py:14-20), descomente a linha do `set -e` abaixo.
set -l envfile $HOME/work/api_gv3/.env

if status is-interactive; and test -r $envfile
    for kv in (bash -c '
        set -a; . "$1"; set +a
        for k in $(grep -oE "^[A-Za-z_][A-Za-z0-9_]*=" "$1" | tr -d =); do
            printf "%s=%s\0" "$k" "${!k}"
        done' _ $envfile | string split0)
        set -l parts (string split -m1 = -- $kv)
        set -gx $parts[1] $parts[2]
    end
    # set -e ENVIRONMENT ENV_KEY ENV_SERVER_URL ENV_SERVER_RESOURCES
end
