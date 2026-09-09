#!/usr/bin/env bash
# Dibuja el monito dieciochero en el terminal. Version macOS / Linux.
#
# Cada celda de terminal es el doble de alta que de ancha, asi que un pixel
# cuadrado se hace con medio bloque: color de texto arriba, color de fondo
# abajo. Salen DOS filas de arte por linea de terminal.
#
# Uso:  ./render-monito.sh                  -> uno al azar de los tres
#       ./render-monito.sh huaso
#       ./render-monito.sh volantin --sangria 2
#       ./render-monito.sh --banner --modelo "Opus 5"   -> con lineas del banner
#
# Compatible con bash 3.2 (el que trae macOS): sin arrays asociativos.

set -u

SPRITE="aleatorio"
SANGRIA=1
BANNER=0
MODELO=""

while [ $# -gt 0 ]; do
  case "$1" in
    --banner)  BANNER=1; shift ;;
    --modelo)  MODELO="${2:-}"; shift 2 ;;
    --sangria) SANGRIA="${2:-1}"; shift 2 ;;
    *)         SPRITE="$1"; shift ;;
  esac
done

if [ "$SPRITE" = "aleatorio" ]; then
  case $(( RANDOM % 3 )) in
    0) SPRITE="huaso" ;;
    1) SPRITE="bandera" ;;
    *) SPRITE="volantin" ;;
  esac
fi

# --- Paleta (RGB) ---
color_of() {
  case "$1" in
    c) printf '231;72;86'   ;;  # coral, el color original del bicho
    p) printf '217;164;65'  ;;  # paja
    a) printf '43;76;155'   ;;  # azul
    r) printf '168;35;46'   ;;  # rojo
    b) printf '237;231;219' ;;  # lana
    h) printf '107;98;89'   ;;  # hilo del volantin
    n) printf '28;26;24'    ;;  # negro de la chupalla
    w) printf '237;231;219' ;;  # cinta blanca
    *) printf ''            ;;  # fondo
  esac
}

# --- Sprites ---
# Cabeza y patitas conservan la grilla original del bicho: 17 de ancho,
# ojos en las columnas 4 y 12, cuatro patitas.
sprite_rows() {
  case "$1" in
    huaso) cat <<'EOF'
.....nnnnnnn.....
.....wwwwwww.....
nnnnnnnnnnnnnnnnn
..ccccccccccccc..
..cc.ccccccc.cc..
aaaaaaaaaaaaaaaaa
..arrrrrrrrrrra..
....c.c...c.c....
EOF
    ;;
    bandera) cat <<'EOF'
.....nnnnnnn.....
.....wwwwwww.....
nnnnnnnnnnnnnnnnn
..ccccccccccccc..
..cc.ccccccc.cc..
aabaaabbbbbbbbbbb
..rrrrrrrrrrrrr..
....c.c...c.c....
EOF
    ;;
    volantin) cat <<'EOF'
.....nnnnnnn......r..
.....wwwwwww.....rrr.
nnnnnnnnnnnnnnnnn.r..
..ccccccccccccc...h..
..cc.ccccccc.cc..h...
aaaaaaaaaaaaaaaaah...
..arrrrrrrrrrra......
....c.c...c.c........
EOF
    ;;
    huaso-paja) cat <<'EOF'
.....ppppppp.....
ppppppppppppppppp
..ccccccccccccc..
..cc.ccccccc.cc..
aaaaaaaaaaaaaaaaa
..arrrrrrrrrrra..
....c.c...c.c....
EOF
    ;;
    bandera-paja) cat <<'EOF'
.....ppppppp.....
ppppppppppppppppp
..ccccccccccccc..
..cc.ccccccc.cc..
aabaaabbbbbbbbbbb
..rrrrrrrrrrrrr..
....c.c...c.c....
EOF
    ;;
    volantin-paja) cat <<'EOF'
.....ppppppp......r..
ppppppppppppppppp.rrr
..ccccccccccccc...r..
..cc.ccccccc.cc...h..
aaaaaaaaaaaaaaaaah...
..arrrrrrrrrrra......
....c.c...c.c........
EOF
    ;;
    *)
      echo "Sprite desconocido: $1" >&2
      echo "Opciones: huaso, bandera, volantin, huaso-paja, bandera-paja, volantin-paja, aleatorio" >&2
      exit 1
    ;;
  esac
}

# Cargamos las filas en un array indexado (bash 3.2 no tiene mapfile)
ROWS=()
while IFS= read -r linea; do
  ROWS[${#ROWS[@]}]="$linea"
done <<EOF
$(sprite_rows "$SPRITE")
EOF

TOTAL=${#ROWS[@]}
if [ "$TOTAL" -eq 0 ]; then exit 1; fi

# Ancho maximo
ANCHO=0
i=0
while [ $i -lt "$TOTAL" ]; do
  len=${#ROWS[$i]}
  if [ "$len" -gt "$ANCHO" ]; then ANCHO=$len; fi
  i=$(( i + 1 ))
done

ESC=$(printf '\033')
RESET="${ESC}[0m"
ARRIBA=$(printf '\xe2\x96\x80')   # medio bloque superior
ABAJO=$(printf '\xe2\x96\x84')    # medio bloque inferior

MARGEN=$(printf "%${SANGRIA}s" "")

celda() {
  # $1 = indice de fila, $2 = columna. Imprime el RGB o vacio.
  idx=$1; col=$2
  if [ "$idx" -ge "$TOTAL" ]; then printf ''; return; fi
  fila="${ROWS[$idx]}"
  if [ "$col" -ge "${#fila}" ]; then printf ''; return; fi
  color_of "${fila:$col:1}"
}

# --- Lineas de texto al costado (solo con --banner) ---
# El sprite tiene 8 filas = 4 lineas de terminal, y el banner de Claude Code
# tiene 3 lineas de texto. La cuarta es la cuenta regresiva.
TEXTOS=()
if [ "$BANNER" -eq 1 ]; then
  BLOQUE=$(printf '\xe2\x96\x88')   # bloque lleno, para la banderita
  C_PAJA="${ESC}[38;2;217;164;65m"
  C_AZUL="${ESC}[38;2;90;130;220m"
  C_BLANCO="${ESC}[38;2;237;231;219m"
  C_ROJO="${ESC}[38;2;225;80;90m"
  C_TENUE="${ESC}[38;2;138;128;120m"

  # Version real, si claude esta en el PATH
  VERSION=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -n "$VERSION" ]; then
    TEXTOS[${#TEXTOS[@]}]="${C_BLANCO}Claude Code v${VERSION}${RESET}"
  fi

  # La linea del modelo la pasa Claude al invocar la skill: el script no
  # tiene como saber el nombre bonito del modelo de la sesion.
  if [ -n "$MODELO" ]; then
    TEXTOS[${#TEXTOS[@]}]="${C_TENUE}${MODELO}${RESET}"
  fi

  TEXTOS[${#TEXTOS[@]}]="${C_TENUE}$(pwd)${RESET}"

  # --- Cuenta regresiva al 18 ---
  # date -d es GNU, date -j -f es BSD/macOS: probamos el primero y caemos al otro
  epoch_de() {
    if date -d "$1" +%s >/dev/null 2>&1; then
      date -d "$1" +%s
    else
      date -j -f "%Y-%m-%d" "$1" +%s
    fi
  }

  HOY=$(date +%Y-%m-%d)
  ANIO=$(date +%Y)
  HOY_S=$(epoch_de "$HOY")
  D18_S=$(epoch_de "${ANIO}-09-18")
  # Pasado el 19 ya miramos el dieciocho del proximo anio
  D19_S=$(epoch_de "${ANIO}-09-19")
  if [ "$HOY_S" -gt "$D19_S" ]; then
    D18_S=$(epoch_de "$(( ANIO + 1 ))-09-18")
  fi
  DIAS=$(( (D18_S - HOY_S) / 86400 ))

  if [ "$DIAS" -gt 1 ]; then
    FRASE="${C_PAJA}faltan ${C_BLANCO}${DIAS}${C_PAJA} días pal 18${RESET}"
  elif [ "$DIAS" -eq 1 ]; then
    FRASE="${C_PAJA}mañana es el 18${RESET}"
  elif [ "$DIAS" -eq 0 ]; then
    FRASE="${C_ROJO}¡VIVA CHILE!${RESET}"
  else
    FRASE="${C_PAJA}sigue el carrete, es 19${RESET}"
  fi

  BANDERITA="${C_AZUL}${BLOQUE}${C_BLANCO}${BLOQUE}${C_ROJO}${BLOQUE}${RESET}"
  TEXTOS[${#TEXTOS[@]}]="${BANDERITA} ${FRASE}"
fi

# Recorremos de dos en dos filas: la de arriba pinta el texto, la de abajo el fondo
NLINEA=0
y=0
while [ $y -lt "$TOTAL" ]; do
  linea="$MARGEN"
  x=0
  while [ $x -lt "$ANCHO" ]; do
    sup=$(celda "$y" "$x")
    inf=$(celda $(( y + 1 )) "$x")

    if [ -z "$sup" ] && [ -z "$inf" ]; then
      linea="${linea} "
    elif [ -n "$sup" ] && [ -z "$inf" ]; then
      linea="${linea}${ESC}[38;2;${sup}m${ARRIBA}${RESET}"
    elif [ -z "$sup" ] && [ -n "$inf" ]; then
      linea="${linea}${ESC}[38;2;${inf}m${ABAJO}${RESET}"
    else
      linea="${linea}${ESC}[38;2;${sup}m${ESC}[48;2;${inf}m${ARRIBA}${RESET}"
    fi
    x=$(( x + 1 ))
  done
  # Cada linea del sprite ocupa exactamente $ANCHO celdas visibles, asi que
  # el texto queda alineado sin tener que medir los codigos ANSI.
  if [ "$NLINEA" -lt "${#TEXTOS[@]}" ]; then
    linea="${linea}  ${TEXTOS[$NLINEA]}"
  fi
  NLINEA=$(( NLINEA + 1 ))

  printf '%s\n' "$linea"
  y=$(( y + 2 ))
done
