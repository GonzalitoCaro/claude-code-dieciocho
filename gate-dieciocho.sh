#!/usr/bin/env bash
# Filtro barato para el hook UserPromptSubmit: corre en CADA prompt, asi que
# decide antes de levantar nada mas pesado.
#
# OJO: hay que mirar SOLO el campo prompt, no el JSON entero. El JSON trae el
# cwd y el transcript_path, y si el proyecto se llama algo con "dieciocho"
# adentro (por ejemplo la carpeta de este mismo repo) el grep calza con todos
# los mensajes y el banner aparece en cada uno.
set -u
BASE="$(cd "$(dirname "$0")" && pwd)"

ENTRADA=$(cat)
PROMPT=$(printf '%s' "$ENTRADA" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1)
case "$PROMPT" in
  *[Dd]ieciocho*) ;;
  *) exit 0 ;;
esac

exec bash "$BASE/prompt-monito.sh"
