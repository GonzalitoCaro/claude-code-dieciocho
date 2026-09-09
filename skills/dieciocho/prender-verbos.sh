#!/usr/bin/env bash
# Hook SessionStart: prende los verbos dieciocheros del spinner, una sola vez.
#
# Un plugin no puede traer spinnerVerbs en su propio settings.json: Claude Code
# solo honra "agent" y "subagentStatusLine" desde un plugin. La unica forma de
# que los verbos queden prendidos al instalar es que un hook escriba la clave
# en el ~/.claude/settings.json del usuario. Eso hace este script, con reglas:
#
# - Corre en cada arranque, asi que sale al tiro si ya hizo su pega: deja una
#   marca en ~/.claude/dieciocho-verbos.hecho y no vuelve a tocar nada.
# - Si el usuario ya tiene spinnerVerbs (suyos o los nuestros), no los pisa.
#   Solo deja la marca.
# - Si el settings.json no es JSON valido, no lo toca y no deja marca.
# - Para apagar los verbos basta sacar la clave: la marca queda y el hook no
#   la vuelve a poner. La skill sabe hacerlo si el usuario lo pide.
#
# El JSON se edita con lo que haya: en Windows siempre PowerShell (python3 en
# Windows puede ser el stub de la Microsoft Store, que abre la tienda en vez
# de correr), y en macOS/Linux python3, node o jq, en ese orden. Sin ninguno,
# no hace nada y la skill lo ofrece a mano.
set -u
BASE="$(cd "$(dirname "$0")" && pwd)"
VERBOS="$BASE/verbos.json"
SETTINGS="${DIECIOCHO_SETTINGS:-$HOME/.claude/settings.json}"
MARCA="$(dirname "$SETTINGS")/dieciocho-verbos.hecho"

[ -f "$MARCA" ] && exit 0
[ -f "$VERBOS" ] || exit 0

if [ -f "$SETTINGS" ] && grep -q '"spinnerVerbs"' "$SETTINGS"; then
  : > "$MARCA"
  exit 0
fi

es_windows() {
  case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; esac
  return 1
}

# Elige el motor. DIECIOCHO_MOTOR lo fuerza, para probar.
MOTOR="${DIECIOCHO_MOTOR:-}"
if [ -z "$MOTOR" ]; then
  if es_windows; then
    MOTOR=powershell
  elif command -v python3 >/dev/null 2>&1; then
    MOTOR=python3
  elif command -v node >/dev/null 2>&1; then
    MOTOR=node
  elif command -v jq >/dev/null 2>&1; then
    MOTOR=jq
  else
    exit 0
  fi
fi

SALIDA="$SETTINGS.dieciocho.tmp"
rm -f "$SALIDA"
ok=1
case "$MOTOR" in
  powershell)
    # Rutas en formato Windows, convertidas a mano: la conversion automatica
    # del bash de Git se equivoca con rutas tipo /tmp/... y PowerShell termina
    # escribiendo en cualquier parte.
    if command -v cygpath >/dev/null 2>&1; then
      S_W=$(cygpath -w "$SETTINGS"); V_W=$(cygpath -w "$VERBOS"); T_W=$(cygpath -w "$SALIDA")
    else
      S_W=$SETTINGS; V_W=$VERBOS; T_W=$SALIDA
    fi
    powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$BASE/prender-verbos.ps1" -Settings "$S_W" -Verbos "$V_W" -Salida "$T_W" >/dev/null 2>&1 || ok=0 ;;
  python3)
    python3 - "$SETTINGS" "$VERBOS" "$SALIDA" <<'PY' >/dev/null 2>&1 || ok=0
import json, os, sys
settings, verbos, salida = sys.argv[1:4]
d = {}
if os.path.exists(settings):
    with open(settings, encoding="utf-8-sig") as f:
        d = json.load(f)
    if not isinstance(d, dict):
        sys.exit(1)
with open(verbos, encoding="utf-8-sig") as f:
    d["spinnerVerbs"] = json.load(f)
with open(salida, "w", encoding="utf-8", newline="\n") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    ;;
  node)
    node - "$SETTINGS" "$VERBOS" "$SALIDA" <<'JS' >/dev/null 2>&1 || ok=0
const fs = require("fs");
const [settings, verbos, salida] = process.argv.slice(2);
const leer = p => JSON.parse(fs.readFileSync(p, "utf8").replace(/^﻿/, ""));
let d = fs.existsSync(settings) ? leer(settings) : {};
if (d === null || typeof d !== "object" || Array.isArray(d)) process.exit(1);
d.spinnerVerbs = leer(verbos);
fs.writeFileSync(salida, JSON.stringify(d, null, 2) + "\n");
JS
    ;;
  jq)
    if [ -f "$SETTINGS" ]; then
      jq --slurpfile v "$VERBOS" '. + {spinnerVerbs: $v[0]}' "$SETTINGS" > "$SALIDA" 2>/dev/null || ok=0
    else
      jq '{spinnerVerbs: .}' "$VERBOS" > "$SALIDA" 2>/dev/null || ok=0
    fi ;;
  *) exit 0 ;;
esac

if [ "$ok" -eq 1 ] && [ -s "$SALIDA" ] && grep -q '"spinnerVerbs"' "$SALIDA"; then
  mv -f "$SALIDA" "$SETTINGS" && : > "$MARCA"
  printf '{"systemMessage":"Verbos dieciocheros prendidos en el spinner (spinnerVerbs en settings.json). Para apagarlos, pidele a Claude que los saque."}\n'
else
  rm -f "$SALIDA"
fi
exit 0
