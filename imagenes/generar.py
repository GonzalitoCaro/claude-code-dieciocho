#!/usr/bin/env python3
"""Genera las fotos de los 12 monitos, en imagenes/.

Las arma desde la salida REAL del renderizador, parseando sus codigos ANSI, no
redibujando los sprites por separado. Asi no pueden quedar desfasadas del
codigo: si cambia un sprite, se corre esto y listo.

Necesita Pillow. Uso: python imagenes/generar.py
"""
import os
import re
import shutil
import subprocess
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "imagenes")
FONDO = (12, 12, 12)          # el negro del terminal
ANCHO_CELDA, ALTO_CELDA = 14, 28   # una celda es el doble de alta que de ancha

PONCHOS = ("huaso", "bandera", "chamanto")
SOMBREROS = ("negra", "paja")


def buscar_bash():
    # En Windows, el bash del PATH suele ser el de WSL y no sirve.
    if os.name == "nt":
        candidato = r"C:\Program Files\Git\bin\bash.exe"
        if os.path.exists(candidato):
            return candidato
    return shutil.which("bash") or "bash"


def celdas_de(linea):
    """Convierte una linea con codigos ANSI en una lista de colores o None."""
    fuera, i = [], 0
    while i < len(linea):
        m = re.match(r"\x1b\[38;2;(\d+);(\d+);(\d+)m\u2588\x1b\[0m", linea[i:])
        if m:
            fuera.append((int(m.group(1)), int(m.group(2)), int(m.group(3))))
            i += m.end()
            continue
        if linea[i] == " ":
            fuera.append(None)
            i += 1
            continue
        m = re.match(r"\x1b\[[0-9;]*m", linea[i:])
        if m:
            i += m.end()
            continue
        i += 1
    return fuera


def main():
    bash = buscar_bash()
    script = os.path.join(RAIZ, "skills", "dieciocho", "render-monito.sh")
    os.makedirs(SALIDA, exist_ok=True)
    hechas = 0
    for poncho in PONCHOS:
        for sombrero in SOMBREROS:
            for cola in ("", "-volantin"):
                nombre = poncho + "-" + sombrero + cola
                r = subprocess.run([bash, script, nombre, "--sangria", "0"],
                                   capture_output=True)
                texto = r.stdout.decode("utf-8").replace("\r", "").rstrip("\n")
                if not texto.strip():
                    print("sin salida:", nombre, file=sys.stderr)
                    continue
                filas = [celdas_de(l) for l in texto.split("\n")]
                ancho = max(len(f) for f in filas)
                img = Image.new("RGB",
                                (ancho * ANCHO_CELDA, len(filas) * ALTO_CELDA),
                                FONDO)
                px = img.load()
                for y, fila in enumerate(filas):
                    for x, color in enumerate(fila):
                        if color is None:
                            continue
                        for dy in range(ALTO_CELDA):
                            for dx in range(ANCHO_CELDA):
                                px[x * ANCHO_CELDA + dx, y * ALTO_CELDA + dy] = color
                img.save(os.path.join(SALIDA, nombre + ".png"))
                hechas += 1
    print("generadas", hechas, "imagenes en", SALIDA)


if __name__ == "__main__":
    main()
