#!/usr/bin/env bash
# Filtro barato para el hook UserPromptSubmit: corre en CADA prompt, asi que
# grep decide antes de levantar nada mas pesado. grep consume el stdin, por eso
# el renderizador va directo.
set -u
BASE="$(cd "$(dirname "$0")" && pwd)"
grep -qi dieciocho || exit 0
exec bash "$BASE/prompt-monito.sh"
