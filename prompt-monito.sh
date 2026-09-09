#!/usr/bin/env bash
# Hook UserPromptSubmit (parte pesada): dibuja el banner dieciochero.
# Lo llama gate-dieciocho.sh, que ya filtro el prompt.
set -u
BASE="$(cd "$(dirname "$0")" && pwd)"

# Linea del modelo, leida de la configuracion del usuario para que diga lo
# mismo que el banner de verdad. Sin parser de JSON: basta con un grep.
MODELO=""
CFG="$HOME/.claude/settings.json"
if [ -f "$CFG" ]; then
  ID=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$CFG" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  case "$ID" in
    opus*)   MODELO="Opus 5" ;;
    sonnet*) MODELO="Sonnet 5" ;;
    haiku*)  MODELO="Haiku 4.5" ;;
    fable*)  MODELO="Fable 5.1" ;;
    "")      MODELO="" ;;
    *)       MODELO="$ID" ;;
  esac
  case "$ID" in *"[1m]"*) MODELO="$MODELO (1M context)" ;; esac
  ESFUERZO=$(grep -o '"effortLevel"[[:space:]]*:[[:space:]]*"[^"]*"' "$CFG" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  [ -n "$ESFUERZO" ] && [ -n "$MODELO" ] && MODELO="$MODELO with $ESFUERZO effort"
fi

if [ -n "$MODELO" ]; then
  ARTE=$(bash "$BASE/render-monito.sh" --banner --modelo "$MODELO" 2>/dev/null) || exit 0
else
  ARTE=$(bash "$BASE/render-monito.sh" --banner 2>/dev/null) || exit 0
fi
[ -z "$ARTE" ] && exit 0

# Mismo escapado que sessionstart-monito.sh, pero aca SI puede venir la ruta
# del proyecto, asi que tambien escapamos comillas y backslashes.
# El backslash se fabrica con sprintf("%c", 92): pasarlo como literal hace que
# awk lo interprete como escape y lo convierta en un salto de linea real.
JSON=$(printf '%s' "$ARTE" | awk -v esc="$(printf '\033')" '
  BEGIN { bs = sprintf("%c", 92); comilla = sprintf("%c", 34) }
  {
    salida = ""
    for (i = 1; i <= length($0); i++) {
      ch = substr($0, i, 1)
      if (ch == esc)          { salida = salida bs "u001b" }
      else if (ch == bs)      { salida = salida bs bs }
      else if (ch == comilla) { salida = salida bs comilla }
      else                    { salida = salida ch }
    }
    printf "%s%s", salida, bs "n"
  }')

printf '{"systemMessage":"%s"}\n' "$JSON"
