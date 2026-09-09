#!/usr/bin/env bash
# Dibuja el monito dieciochero en el terminal. Version macOS / Linux.
#
# GEOMETRIA: el bicho original de Claude Code usa un pixel por celda de
# terminal, y una celda es el doble de alta que de ancha. Osea sus pixeles son
# rectangulos parados, no cuadrados. Aca hacemos lo mismo -- una fila de arte
# por linea -- para que el huaso tenga las mismas proporciones. (Con medio
# bloque los pixeles salen cuadrados y el monito queda achatado a la mitad.)
#
# Uso:  ./render-monito.sh                     -> uno al azar de los tres
#       ./render-monito.sh volantin
#       ./render-monito.sh --cuenta            -> con la cuenta regresiva
#       ./render-monito.sh --banner --modelo "Opus 5"
#
# Compatible con bash 3.2 (el que trae macOS): sin arrays asociativos.

set -u

SPRITE="aleatorio"; SANGRIA=1; BANNER=0; CUENTA=0; MODELO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --banner)  BANNER=1; shift ;;
    --cuenta)  CUENTA=1; shift ;;
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
# El negro de la chupalla NO es negro puro: sobre el fondo oscuro del terminal
# un negro real desaparece y solo se ve la cinta blanca flotando.
color_of() {
  case "$1" in
    c) printf '231;72;86'   ;;  # coral, el color original del bicho
    p) printf '217;164;65'  ;;  # paja
    a) printf '43;76;155'   ;;  # azul
    r) printf '168;35;46'   ;;  # rojo
    b) printf '237;231;219' ;;  # lana
    h) printf '107;98;89'   ;;  # hilo del volantin
    n) printf '53;48;43'    ;;  # negro de la chupalla
    w) printf '237;231;219' ;;  # cinta blanca
    *) printf ''            ;;  # fondo
  esac
}

# --- Sprites ---
# 17 columnas, ojos en las columnas 4 y 12, cuatro patitas: la grilla exacta
# del bicho original, con dos filas de sombrero encima.
sprite_rows() {
  case "$1" in
    huaso) cat <<'EOF'
.....nnnnnnn.....
nnnnwwwwwwwwwnnnn
..ccccccccccccc..
..cc.ccccccc.cc..
aaaaaaaaaaaaaaaaa
..arrrrrrrrrrra..
....c.c...c.c....
EOF
    ;;
    bandera) cat <<'EOF'
.....nnnnnnn.....
nnnnwwwwwwwwwnnnn
..ccccccccccccc..
..cc.ccccccc.cc..
aabaaabbbbbbbbbbb
..rrrrrrrrrrrrr..
....c.c...c.c....
EOF
    ;;
    volantin|volantin-paja) cat <<'EOF'
.....ppppppp.......r.
ppppppppppppppppp.rrr
..ccccccccccccc....r.
..cc.ccccccc.cc...h..
aaaaaaaaaaaaaaaaah...
..arrrrrrrrrrra......
....c.c...c.c........
EOF
    ;;
    volantin-negro) cat <<'EOF'
.....nnnnnnn.......r.
nnnnwwwwwwwwwnnnn.rrr
..ccccccccccccc....r.
..cc.ccccccc.cc...h..
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
    *)
      echo "Sprite desconocido: $1" >&2
      echo "Opciones: huaso, bandera, volantin, huaso-paja, bandera-paja, volantin-negro, aleatorio" >&2
      exit 1
    ;;
  esac
}

# bash 3.2 no tiene mapfile
ROWS=()
while IFS= read -r linea; do
  ROWS[${#ROWS[@]}]="$linea"
done <<EOF
$(sprite_rows "$SPRITE")
EOF

TOTAL=${#ROWS[@]}
[ "$TOTAL" -eq 0 ] && exit 1

ANCHO=0
i=0
while [ $i -lt "$TOTAL" ]; do
  len=${#ROWS[$i]}
  [ "$len" -gt "$ANCHO" ] && ANCHO=$len
  i=$(( i + 1 ))
done

ESC=$(printf '\033')
RESET="${ESC}[0m"
BLOQUE=$(printf '\xe2\x96\x88')     # bloque lleno: un pixel = una celda
ESTRELLA=$(printf '\xe2\x98\x85')   # estrella de la bandera
MARGEN=$(printf "%${SANGRIA}s" "")

# --- Texto al costado ---
# TEXTOS es un array indexado por fila del sprite; "" significa sin texto.
TEXTOS=()
i=0
while [ $i -lt "$TOTAL" ]; do TEXTOS[$i]=""; i=$(( i + 1 )); done

if [ "$BANNER" -eq 1 ] || [ "$CUENTA" -eq 1 ]; then
  C_PAJA="${ESC}[38;2;217;164;65m"
  C_BLANCO="${ESC}[38;2;237;231;219m"
  C_ROJO="${ESC}[38;2;225;80;90m"
  C_TENUE="${ESC}[38;2;138;128;120m"

  FILA_CUENTA=4
  if [ "$BANNER" -eq 1 ]; then
    F=1
    VERSION=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -n "$VERSION" ]; then
      TEXTOS[$F]="${C_BLANCO}Claude Code v${VERSION}${RESET}"; F=$(( F + 1 ))
    fi
    if [ -n "$MODELO" ]; then
      TEXTOS[$F]="${C_TENUE}${MODELO}${RESET}"; F=$(( F + 1 ))
    fi
    TEXTOS[$F]="${C_TENUE}$(pwd)${RESET}"
    FILA_CUENTA=$(( F + 2 ))
  fi

  # date -d es GNU, date -j -f es BSD/macOS: probamos el primero y caemos al otro
  epoch_de() {
    if date -d "$1" +%s >/dev/null 2>&1; then date -d "$1" +%s
    else date -j -f "%Y-%m-%d" "$1" +%s; fi
  }
  ANIO=$(date +%Y)
  HOY_S=$(epoch_de "$(date +%Y-%m-%d)")
  D18_S=$(epoch_de "${ANIO}-09-18")
  if [ "$HOY_S" -gt "$(epoch_de "${ANIO}-09-19")" ]; then
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

  # Estrella sola: tres bloques azul/blanco/rojo se leen como Francia.
  [ "$FILA_CUENTA" -lt "$TOTAL" ] && TEXTOS[$FILA_CUENTA]="${C_BLANCO}${ESTRELLA}${RESET} ${FRASE}"
fi

# --- Dibujo: una fila de arte por linea de terminal ---
y=0
while [ $y -lt "$TOTAL" ]; do
  fila="${ROWS[$y]}"
  linea="$MARGEN"
  x=0
  while [ $x -lt "$ANCHO" ]; do
    if [ "$x" -lt "${#fila}" ]; then col=$(color_of "${fila:$x:1}"); else col=""; fi
    if [ -z "$col" ]; then
      linea="${linea} "
    else
      linea="${linea}${ESC}[38;2;${col}m${BLOQUE}${RESET}"
    fi
    x=$(( x + 1 ))
  done
  [ -n "${TEXTOS[$y]}" ] && linea="${linea}  ${TEXTOS[$y]}"
  printf '%s\n' "$linea"
  y=$(( y + 1 ))
done
