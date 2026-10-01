#!/usr/bin/env bash
# Uso:  source ghuse.sh [alias]
# Carrega .env e exporta as variáveis git/GitHub do usuário escolhido.
# NÃO usa "set -e" pois é feito para ser "sourced" (funciona em bash e zsh).

_GH_SELF="${BASH_SOURCE[0]:-$0}"
export MY_REPOS_ROOT="${MY_REPOS_ROOT:-$(cd "$(dirname "$_GH_SELF")" && pwd)}"

if [ ! -f "$MY_REPOS_ROOT/.env" ]; then
  echo "ERRO: $MY_REPOS_ROOT/.env não encontrado. Rode ./setup.sh primeiro." >&2
  return 1 2>/dev/null || exit 1
fi

set -a; . "$MY_REPOS_ROOT/.env"; set +a

# lê variável pelo nome (compatível com bash e zsh)
_gh_get() { eval "printf '%s' \"\${$1:-}\""; }

_alias="${1:-${GH_DEFAULT:-}}"
if [ -z "$_alias" ]; then
  echo "ERRO: informe o alias (ex.: source ghuse.sh mdelapi)" >&2
  return 1 2>/dev/null || exit 1
fi

_key="$(printf '%s' "$_alias" | tr '[:lower:]-' '[:upper:]_')"

export GH_ALIAS="$_alias"
export GH_USER="$(_gh_get "GH_${_key}_USER")"
export GH_NAME="$(_gh_get "GH_${_key}_NAME")"
export GH_EMAIL="$(_gh_get "GH_${_key}_EMAIL")"
export GH_SSH_KEY="$(_gh_get "GH_${_key}_SSH_KEY")"
export GH_TOKEN="$(_gh_get "GH_${_key}_TOKEN")"

if [ -z "$GH_USER" ]; then
  echo "ERRO: GH_${_key}_USER não definido no .env" >&2
  return 1 2>/dev/null || exit 1
fi

# identidade usada em git commit
export GIT_AUTHOR_NAME="$GH_NAME"
export GIT_COMMITTER_NAME="$GH_NAME"
export GIT_AUTHOR_EMAIL="$GH_EMAIL"
export GIT_COMMITTER_EMAIL="$GH_EMAIL"

if [ -n "$GH_SSH_KEY" ]; then
  if [ ! -f "$GH_SSH_KEY" ]; then
    echo "[ghuse] AVISO: chave SSH nao encontrada ($GH_SSH_KEY); usando HTTPS"
    GH_SSH_KEY=""
  fi
fi

# autenticação: SSH (chave dedicada) e/ou token HTTPS
unset GIT_SSH_COMMAND GIT_ASKPASS
if [ -n "$GH_SSH_KEY" ]; then
  export GIT_SSH_COMMAND="ssh -i $GH_SSH_KEY -o IdentitiesOnly=yes"
fi
if [ -n "$GH_TOKEN" ]; then
  export GIT_ASKPASS="$MY_REPOS_ROOT/bin/askpass.sh"
  export GIT_TERMINAL_PROMPT=0
fi

export GH_WORKDIR="$MY_REPOS_ROOT/$_alias"
mkdir -p "$GH_WORKDIR"

echo "[ghuse] ativo: $GH_ALIAS ($GH_USER) -> $GH_WORKDIR"
unset _alias _key _GH_SELF
