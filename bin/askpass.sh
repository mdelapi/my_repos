#!/usr/bin/env bash
# Usado pelo git via GIT_ASKPASS; responde com GH_USER / GH_TOKEN do ambiente.
case "$1" in
  Username*) printf '%s\n' "$GH_USER" ;;
  Password*) printf '%s\n' "$GH_TOKEN" ;;
esac
