#!/usr/bin/env bash
# Uso: ./sync.sh <alias> <repo> "mensagem do commit"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -lt 3 ]; then
  echo "Uso: $0 <alias> <repo> \"mensagem\"" >&2; exit 1
fi

ALIAS="$1"; REPO="${2##*/}"; MSG="$3"
. "$ROOT/ghuse.sh" "$ALIAS"

DIR="$GH_WORKDIR/$REPO"
[ -d "$DIR/.git" ] || { echo "ERRO: $DIR nao e um repo git" >&2; exit 1; }

cd "$DIR"
git status --short
if [ -z "$(git status --porcelain)" ]; then
  echo "[sync] nada para commitar."
  exit 0
fi

git add -A
git commit -m "$MSG"
git push
