#!/usr/bin/env bash
# Prepara o ambiente local a partir da pasta raiz my_repos.
# Uso: ./setup.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

command -v git >/dev/null || { echo "ERRO: git não instalado." >&2; exit 1; }

# .env
if [ ! -f .env ]; then
  cp .env.example .env
  echo "[setup] .env criado a partir de .env.example -> edite com seus dados."
fi
chmod 600 .env

# permissões dos scripts
chmod +x setup.sh clone.sh ghuse.sh bin/askpass.sh

# pastas por usuário
set -a; . ./.env; set +a
for u in ${GH_USERS:-}; do
  mkdir -p "$ROOT/$u"
  key="$(printf '%s' "$u" | tr '[:lower:]-' '[:upper:]_')"
  sshvar="GH_${key}_SSH_KEY"
  sshkey="$(eval "printf '%s' \"\${$sshvar:-}\"")"
  echo "[setup] pasta: $ROOT/$u"
  if [ -n "$sshkey" ] && [ ! -f "$sshkey" ]; then
    echo "  AVISO: chave SSH não encontrada: $sshkey"
    echo "  Gere com: ssh-keygen -t ed25519 -f \"$sshkey\" -C \"$u\""
    echo "  e adicione a .pub em https://github.com/settings/keys"
  fi
done

echo
echo "Ambiente pronto em: $ROOT"
echo "Próximo passo:  ./clone.sh mdelapi mdelapi/sampleone"
