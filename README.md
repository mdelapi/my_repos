# my_repos

Esqueleto para clonar e manter repositórios GitHub de vários usuários,
cada um com sua identidade (nome, e-mail, chave SSH ou token) vinda de um .env.

Uso rápido:

    ./setup.sh                          # cria .env e as pastas por usuário
    ./clone.sh <alias> <repo>           # clona em my_repos/<alias>/<repo>
    source ./ghuse.sh <alias>           # carrega o ambiente do usuário

Copie .env.example para .env e preencha. O .env nunca é versionado.

Testado clonando o proprio repo.
