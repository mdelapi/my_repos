# Validação da ferramenta de clonagem multiusuário

Registro do que foi testado e verificado no processo de clonar, alterar e enviar
repositórios do GitHub com o `my_repos`. Data dos testes: 30/09/2026.

## 1. Objetivo

Ter uma pasta raiz `my_repos/` que:

- clona repositórios de vários usuários GitHub, cada um em `my_repos/<alias>/<repo>`;
- guarda a identidade de cada usuário (nome, e-mail, chave SSH, token) em um `.env`;
- permite `git add`, `git commit` e `git push` com a identidade certa;
- carrega o ambiente de um usuário com `source ghuse.sh <alias>`.

## 2. Componentes

| Arquivo | Função |
|---|---|
| `setup.sh` | Cria `.env` a partir do `.env.example`, ajusta permissões e cria as pastas por usuário. |
| `ghuse.sh` | Deve ser executado com `source`. Exporta as variáveis git/GitHub do alias escolhido. |
| `clone.sh` | Clona (ou faz `pull`) em `my_repos/<alias>/<repo>` e grava a identidade no repo. |
| `sync.sh` | Faz `add -A`, `commit` e `push` de um repo em um comando. |
| `bin/askpass.sh` | Fornece usuário e token ao git via `GIT_ASKPASS` (HTTPS). |
| `.env.example` | Modelo das variáveis. O `.env` real nunca é versionado. |

Convenção do `.env`: `GH_<ALIAS>_USER`, `_NAME`, `_EMAIL`, `_SSH_KEY`, `_TOKEN`
(alias em maiúsculas, hífen vira `_`).

## 3. Ambientes testados

- macOS com zsh (`source ghuse.sh` funcionou em zsh).
- Linux com bash.
- Máquina nova (macOS): bootstrap a partir do GitHub, sem copiar nada além do `.env`.
- Repositórios usados: `sampleone` (clone, edição, push) e o próprio `my_repos` (auto-clone).

## 4. Testes realizados

| # | Teste | Resultado |
|---|---|---|
| 1 | `setup.sh` cria `.env`, pasta do usuário e avisa sobre chave SSH inexistente | OK |
| 2 | `clone.sh` de repo público por HTTPS, sem token | OK |
| 3 | Identidade (`user.name`, `user.email`) gravada no repo clonado | OK |
| 4 | `git add` e `git commit` locais, sem credencial | OK |
| 5 | `git push` com token no `.env` e `source ghuse.sh` | OK, após ajustar permissões do token (item 5.5) |
| 6 | Isolamento do Keychain com `credential.helper ""` | OK, push passou a usar o token do `.env` |
| 7 | Auto-clone: `my_repos` clonado por `clone.sh`, editado, enviado e puxado de volta na raiz | OK |
| 8 | `ghuse.sh` com chave SSH inexistente cai para HTTPS e avisa | OK |
| 9 | `sync.sh` com arquivo novo (`add`, `commit`, `push`) | OK |
| 10 | `sync.sh` com arquivo removido | OK |
| 11 | `sync.sh` sem alterações responde "nada para commitar" e não cria commit vazio | OK |
| 12 | Autor do commit atribuído à conta correta após usar e-mail verificado | OK |
| 13 | Bootstrap em máquina nova (macOS): clonar o `my_repos`, copiar só o `.env`, `setup.sh` e `clone.sh` do `sampleone` | OK |

Commits de referência:

- `my_repos`: `2d026e7`, `3884f00`, `6e25bc7` (ciclo do auto-clone), `c159796` (patch do `ghuse.sh`), `40d3a69` (`sync.sh`).
- `sampleone`: `2c8e0da` (primeiro push), `fa26253` e `5a21163` (testes do `sync.sh`).

## 5. Problemas encontrados e soluções

### 5.1 Arquivos baixados com nomes errados
Arquivos que começam com ponto perderam o ponto no download (`env.example`,
`gitignore`) e `askpass.sh` ficou fora de `bin/`.
Solução: renomear para `.env.example` e `.gitignore` e mover `askpass.sh` para `bin/`.

### 5.2 `.env` com aspas abertas
O erro `unexpected EOF while looking for matching "` indica aspas sem fechar.
Solução: recriar o `.env` limpo e validar com `bash -n .env`.

### 5.3 Clone via SSH com chave inexistente
O `.env.example` aponta para `~/.ssh/id_ed25519_mdelapi`. Se a chave não existe, o
clone escolhe SSH e falha com `Permission denied (publickey)`.
Solução: deixar `SSH_KEY=""` para usar HTTPS. O `ghuse.sh` agora detecta a chave
ausente, avisa e cai para HTTPS (teste 8).

### 5.4 Credencial errada vinda do Keychain (macOS)
O push retornou 403 com o nome de outra conta GitHub. O git consulta o
`credential.helper` (`osxkeychain`) antes do `GIT_ASKPASS`, e usou uma credencial
antiga salva.
Solução:

```bash
printf "protocol=https\nhost=github.com\n\n" | git credential-osxkeychain erase
git config credential.helper ""      # no repo; o clone.sh já faz isso quando há token
```

### 5.5 403 com a identidade correta
Depois de remover o Keychain, o erro passou a citar o usuário certo, mas continuou
403. A causa provável era o token fine-grained sem **Contents: Read and write**
no repositório. Após ajustar as permissões do token, o push funcionou. Observação:
a chamada `GET /repos/...` mostra as permissões do dono, não as do token, e por
isso não serve para diagnosticar esse caso.

### 5.6 E-mail do commit
O `.env` ficou com o e-mail de exemplo (`seu-email@exemplo.com`) e os primeiros
commits saíram com ele. O GitHub liga o commit à conta pelo **e-mail do autor**, não
pelo token, e o commit chegou a aparecer atribuído a uma conta inesperada
(causa não esclarecida). Com um e-mail verificado na conta correta, os commits
passaram a aparecer como esse usuário.
Correção do commit mais recente de um repo novo:

```bash
git commit --amend --reset-author --no-edit
git push --force-with-lease
```

No `sampleone` o commit antigo foi mantido, para não reescrever o histórico de um
repo público.

### 5.7 Comandos fora do diretório certo
Um `cd` que falhou deixou os comandos seguintes rodando na pasta errada, e um commit
de teste foi para a raiz em vez do clone.
Solução: encadear com `&&` para parar no primeiro erro.

### 5.8 `sed -i` difere entre macOS e Linux
No macOS é `sed -i ''`; no Linux, `sed -i`.

### 5.9 Pasta `docs/` ignorada pelo `.gitignore`
O `.gitignore` do projeto tem a regra `/*/`, que ignora toda pasta na raiz para
deixar de fora os repositórios clonados (`<alias>/`). Por isso uma pasta nova como
`docs/` não aparecia no `git status`, e a única exceção existente era `!/bin/`.
Diagnóstico e solução:

```bash
git check-ignore -v docs/VALIDACAO.md    # aponta a linha /*/ do .gitignore
echo '!/docs/' >> .gitignore
```
Qualquer pasta nova na raiz que deva ser versionada precisa de uma linha `!/nome/`.

### 5.10 Comentários com `#` no zsh interativo
Ao colar comandos com comentários no zsh, o `#` não é tratado como comentário e o
texto seguinte vira argumento (por exemplo, `grep: deve: No such file or directory`).
Os resultados reais dos comandos não são afetados. Solução: `setopt interactivecomments`
na sessão (ou no `~/.zshrc`), ou colar os comandos sem comentários.

## 6. Fluxo recomendado

```bash
./setup.sh                                  # uma vez
./clone.sh <alias> <repo>                   # clonar
source ./ghuse.sh <alias>                   # em terminal novo, antes do push
cd <alias>/<repo> && git status
git add . && git commit -m "mensagem" && git push
# ou, em um comando, da raiz:
./sync.sh <alias> <repo> "mensagem"
```

Todos os comandos git rodam dentro de `my_repos/<alias>/<repo>`. A pasta `my_repos/`
em si só é um repositório porque este projeto foi publicado como tal.

## 7. Segurança

- `.env` está no `.gitignore` e com permissão 600. Antes de qualquer `git add`,
  confira com `git status --short` que `.env` e as pastas de clones não aparecem.
- O token fica em texto puro no `.env`. Em caso de exposição, revogue-o em
  Developer settings e gere outro.
- O e-mail do autor fica visível no histórico de repositórios públicos. O endereço
  noreply do GitHub evita isso.
- Tokens fine-grained devem ter acesso só aos repositórios necessários.

## 8. Não testado

- Clone e push via SSH (nenhuma chave foi gerada nos ambientes de teste).
- Um segundo usuário GitHub com alias próprio (isolamento entre contas).
- Repositórios privados.
- Renovação de token expirado.
