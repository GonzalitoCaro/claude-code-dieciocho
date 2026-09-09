#!/usr/bin/env bash
# Hook SessionStart: dibuja el monito dieciochero debajo del banner de arranque.
# Ver la explicacion completa en sessionstart-monito.ps1.
set -u
BASE="$(cd "$(dirname "$0")" && pwd)"
ARTE=$(bash "$BASE/render-monito.sh" --cuenta 2>/dev/null) || exit 0
[ -z "$ARTE" ] && exit 0

# JSON estricto no acepta caracteres de control dentro de un string, y el arte
# esta lleno de ESC. Tres trampas, las tres ya nos mordieron:
#
# 1. El ESC no se reemplaza con sed ni con gsub: en el texto de reemplazo la
#    secuencia backslash-u significa otra cosa segun la implementacion (GNU sed
#    la lee como "pasa a mayuscula") y se come el escape.
# 2. El salto de linea no puede ir en el formato de printf: awk interpreta los
#    escapes del formato y lo convierte en un salto real.
# 3. Tampoco sirve pasarlo como argumento: este awk convierte el literal
#    "backslash-n" en salto real igual. Por eso el backslash se fabrica con
#    sprintf("%c", 92), que no pasa por el lexer de escapes.
#
# En modo --cuenta el arte no trae comillas ni backslashes, asi que el ESC y
# los saltos son lo unico que hay que escapar. (Con --banner NO valdria: ahi
# entra la ruta, que en Windows viene con backslashes.)
JSON=$(printf '%s' "$ARTE" | awk -v esc="$(printf '\033')" '
  BEGIN { bs = sprintf("%c", 92) }
  {
    salida = ""
    for (i = 1; i <= length($0); i++) {
      ch = substr($0, i, 1)
      if (ch == esc) { salida = salida bs "u001b" } else { salida = salida ch }
    }
    printf "%s%s", salida, bs "n"
  }')

printf '{"systemMessage":"%s"}\n' "$JSON"
