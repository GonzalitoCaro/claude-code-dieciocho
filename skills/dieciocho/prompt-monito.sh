#!/usr/bin/env bash
# Hook UserPromptSubmit (parte pesada): dibuja el banner dieciochero.
# Lo llama gate-dieciocho.sh, que ya filtro el prompt.
set -u
BASE="$(cd "$(dirname "$0")" && pwd)"

# El dibujo queda indentado ~6 columnas y NO se puede pegar al margen: el TUI
# renderiza los mensajes de hook como rama del arbol. Probado y descartado:
# ESC[1G (CHA) y retorno de carro al inicio de cada linea. El TUI los filtra
# al componer el cuadro. No reintentar.

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
  ARTE=$(bash "$BASE/render-monito.sh" --banner --sangria 0 --modelo "$MODELO" 2>/dev/null) || exit 0
else
  ARTE=$(bash "$BASE/render-monito.sh" --banner --sangria 0 2>/dev/null) || exit 0
fi
[ -z "$ARTE" ] && exit 0

# Cuantas filas tiene la terminal. Los rellenos de abajo dependen de esto: con
# un numero fijo el huaso queda a media altura en una ventana chica y pegado
# arriba con un hueco en una grande. Un hook no hereda la terminal: en Windows
# Claude Code lo lanza sin consola, y cualquier cosa que pregunte por "la
# consola" recibe una oculta de 120x30, el tamano por defecto de Windows.
# RawUI, [Console] y mode con devuelven 30 siempre. Lo que si sirve es
# engancharse a la consola del proceso de Claude Code (CLAUDE_PID) y
# preguntarle a esa: eso hace medir-filas.ps1. En macOS/Linux basta con
# /dev/tty. tput no sirve: sin tty inventa 24. Si nada responde, quedan los
# valores fijos de siempre. DIECIOCHO_FILAS fuerza la medida.
medir_filas() {
  f=""
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*)
      if [ -n "${CLAUDE_PID:-}" ]; then
        f=$(powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$BASE/medir-filas.ps1" -ProcesoId "$CLAUDE_PID" 2>/dev/null | tr -cd '0-9')
      fi ;;
    *)
      f=$(stty size </dev/tty 2>/dev/null | cut -d' ' -f1) ;;
  esac
  case "$f" in ''|*[!0-9]*) f="" ;; esac
  printf '%s' "$f"
}
FILAS="${DIECIOCHO_FILAS:-$(medir_filas)}"
case "$FILAS" in ''|*[!0-9]*) FILAS="" ;; esac
if [ -n "$FILAS" ] && [ "$FILAS" -gt 0 ]; then
  # Arriba, una pantalla entera: el banner original sale por el techo seguro.
  # Abajo, lo que sobra tras descontar el arte (7 lineas), los 2 saltos que el
  # TUI mete entre mensajes y la zona de abajo (respuesta, estado, prompt,
  # barra), que son unas 10 filas. Medido en pantallazos: con ABAJO = FILAS - 17
  # la primera fila del arte cae en la fila 1 de la pantalla. Se dejan 2 mas
  # para que quede una fila en blanco encima, como en el banner original, y
  # para que una respuesta de dos lineas no le corte la chupalla.
  EMPUJE_DEF=$FILAS
  ABAJO_DEF=$(( FILAS - 19 ))
  [ "$ABAJO_DEF" -lt 0 ] && ABAJO_DEF=0
else
  EMPUJE_DEF=40
  ABAJO_DEF=14
fi

# Simular que el banner original se borro: no se puede tocar, pero si se puede
# empujar fuera de la vista. Con suficientes lineas en blanco arriba, el banner
# de verdad sale por el techo de la pantalla y abajo queda solo el dieciochero.
# DIECIOCHO_EMPUJE=0 lo desactiva.
EMPUJE="${DIECIOCHO_EMPUJE:-$EMPUJE_DEF}"
if [ "$EMPUJE" -gt 0 ] 2>/dev/null; then
  # OJO: no usar $(...) para armar el relleno. La sustitucion de comandos borra
  # todos los saltos de linea del final y el relleno queda vacio. Se acumula
  # dentro de la variable, con el salto literal adentro de las comillas.
  RELLENO=""
  i=0
  while [ $i -lt "$EMPUJE" ]; do
    RELLENO="$RELLENO
"
    i=$(( i + 1 ))
  done
  ARTE="${RELLENO}${ARTE}"
fi

# Subir el banner: la vista queda anclada abajo, asi que lo que lo empuja hacia
# arriba es el relleno de ABAJO, no el de arriba. DIECIOCHO_EMPUJE_ABAJO=0 lo deja
# a media pantalla como antes.
# Las lineas de abajo llevan un espacio, no van vacias: awk descarta el ultimo
# registro si el texto termina en saltos de linea pelados.
ABAJO="${DIECIOCHO_EMPUJE_ABAJO:-$ABAJO_DEF}"
if [ "$ABAJO" -gt 0 ] 2>/dev/null; then
  i=0
  while [ $i -lt "$ABAJO" ]; do
    ARTE="$ARTE
 "
    i=$(( i + 1 ))
  done
fi

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

# additionalContext se lo lleva Claude como contexto, no el usuario. Con eso la
# skill sabe que el hook esta instalado y ya dibujo, y no vuelve a dibujar.
AVISO="El hook dieciocho ya dibujo el banner en pantalla. No corras ningun comando para dibujarlo de nuevo."
printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$JSON" "$AVISO"
