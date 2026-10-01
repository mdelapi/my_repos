#!/usr/bin/env bash
# Uso: ./clone.sh <alias> <repo>   (URL, owner/repo ou só repo)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -lt 2 ]; then
  echo "Uso: $0 <alias> <repo>" >&2; exit 1
fi

ALIAS="$1"; REPO="$2"
. "$ROOT/ghuse.sh" "$ALIAS"

REPO="${REPO#https://github.com/}"
REPO="${REPO#http://github.com/}"
REPO="${REPO#git@github.com:}"
REPO="${REPO%.git}"
REPO="${REPO%/}"
case "$REPO" in */*) ;; *) REPO="$GH_USER/$REPO" ;; esac

NAME="${REPO##*/}"
DEST="$GH_WORKDIR/$NAME"

if [ -n "$GH_SSH_KEY" ]; then
  URL="git@github.com:$REPO.git"
else
  URL="https://github.com/$REPO.git"
fi

if [ -d "$DEST/.git" ]; then
  echo "[clone] já existe: $DEST -> git pull"
  git -C "$DEST" pull --ff-only
else
  echo "[clone] $URL -> $DEST"
  git clone "$URL" "$DEST"
fi

git -C "$DEST" config user.name  "$GH_NAME"
git -C "$DEST" config user.email "$GH_EMAIL"
if [ -n "$GH_SSH_KEY" ]; then
  git -C "$DEST" config core.sshCommand "ssh -i $GH_SSH_KEY -o IdentitiesOnly=yes"
fi
if [ -n "$GH_TOKEN" ]; then
  git -C "$DEST" config credential.helper ""
fi

echo
echo "Pronto. Para trabalhar:"
echo "  cd $DEST"
echo "  source $ROOT/ghuse.sh $ALIAS   # se abrir um terminal novo"
echo "  git add . && git commit -m \"mensagem\" && git push"
