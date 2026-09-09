---
name: dieciocho
description: Dibuja el bichito de Claude Code vestido de huaso (chupalla negra, poncho, volantín) y prende o apaga la estética dieciochera — verbos chilenos en el spinner y huaso en la statusline. Úsala cuando el usuario escriba /dieciocho, o pida "el bicho dieciochero", "modo dieciochero", "modo fiestas patrias", "ponme el huaso", "sácame el huaso", "apaga lo del 18", o quiera cambiar de dibujo.
---

# Modo dieciochero

Viste de huaso al bicho pixelado de Claude Code y pone el terminal en modo
18 de septiembre. Todo es local, todo es reversible, y la skill es
autocontenida: se puede copiar a otro computador tal cual.

## Al invocarla sin instrucciones

Dibuja un monito al azar con las líneas del banner al lado — versión, modelo,
ruta y la cuenta regresiva al 18. Nada más: no instales ni cambies nada sin
que el usuario lo pida.

**Windows:**
```powershell
& "<BASE>\render-monito.ps1" -Banner -Modelo "<MODELO>"
```

**macOS / Linux:**
```bash
bash "<BASE>/render-monito.sh" --banner --modelo "<MODELO>"
```

`<BASE>` es el directorio base de esta skill, que Claude Code entrega al
invocarla. **Nunca escribas rutas absolutas de un usuario en particular**: esta
skill se comparte.

`<MODELO>` es la línea del modelo tal como sale en el banner de arranque, por
ejemplo `Opus 5 (1M context) with high effort · Claude Team`. El script no
tiene cómo saberla — la sabes tú, que estás corriendo en esa sesión. Ármala con
el modelo actual y, si no estás seguro del plan o del nivel de esfuerzo, pon
solo el nombre del modelo o omite el parámetro: esa línea simplemente no sale.

La versión y la ruta las saca el script solo. La cuenta regresiva se calcula
contra el 18 de septiembre; pasado el 19 apunta al del año siguiente.

Después de dibujar, no expliques el dibujo. Si el usuario quiere otro, vuelve a
correrlo con `-Sprite` / el primer argumento.

## Los dibujos

Tres sprites, todos sobre la grilla real del bicho original — 17 columnas,
ojos en las columnas 4 y 12, cuatro patitas — con chupalla negra de cinta
blanca:

| Sprite | Qué es |
|---|---|
| `huaso` | Chupalla negra y poncho azul con franja roja |
| `bandera` | Chupalla negra y poncho con la bandera: cantón azul con estrella, blanco al lado, franja roja abajo |
| `volantin` | El huaso más un volantín arriba a la derecha, con el hilo bajando al poncho |
| `aleatorio` | Sortea entre los tres. Es el que corre por defecto |

Los tres existen también con chupalla de paja: `huaso-paja`, `bandera-paja`,
`volantin-paja`.

```powershell
& "<BASE>\render-monito.ps1" -Sprite volantin -Sangria 2
```
```bash
bash "<BASE>/render-monito.sh" volantin --sangria 2
```

### Cómo está dibujado

Una celda de terminal es el doble de alta que de ancha, así que un píxel
cuadrado no se hace con `█` sino con `▀`: color de texto arriba, color de
fondo abajo. Salen **dos filas de arte por línea de terminal**, y por eso los
sprites tienen 8 filas — 4 líneas exactas, sin media línea desperdiciada.

Para agregar un sprite nuevo, edítalo en los dos renderizadores (`.ps1` y
`.sh`) con las mismas letras: `c` coral, `p` paja, `a` azul, `r` rojo,
`b` lana, `h` hilo, `n` negro, `w` blanco, `.` fondo.

## Qué se puede y qué no

| Pieza | Se puede |
|---|---|
| Dibujar el monito al invocar la skill | Sí |
| Verbos del spinner ("Rayueleando…") | Sí — `spinnerVerbs` en `settings.json` |
| Huaso permanente en la statusline | Sí — la statusline acepta multilínea |
| **Reemplazar el bicho del banner de inicio** | **No** — está hardcodeado en el binario |

Sobre lo último: en el binario, `BannerConfig` es el banner corporativo de
texto (color de fondo, link, 200 caracteres), no el sprite. No hay setting
para el dibujo. Si el usuario lo pide, dile esto derecho en vez de buscar un
truco: lo más cerca que se llega es la statusline, que sí se ve siempre.

## Verbos del spinner

Están en `verbos.json`, en esta misma carpeta. Para prenderlos, copia ese
objeto como la clave `spinnerVerbs` de `~/.claude/settings.json`:

```json
"spinnerVerbs": { "mode": "replace", "verbs": ["Dieciocheando", "..."] }
```

- `replace` → solo los chilenos.
- `append` → mezclados con los de fábrica.

Para apagarlos, saca la clave. Toman efecto al toque; no hace falta reiniciar.

## Huaso en la statusline (opcional)

Solo si el usuario lo pide. **Antes de tocar nada, respalda la statusline que
ya tenga** — mucha gente tiene la suya armada:

```powershell
Copy-Item "$HOME\.claude\statusline.ps1" "$HOME\.claude\statusline.ps1.bak-pre18" -ErrorAction SilentlyContinue
```

El interruptor es un archivo: si existe `~/.claude/dieciocho.on`, la statusline
dibuja el huaso; si no existe, se comporta normal. Su contenido elige el
tamaño: `cuerpo` (tres líneas) o `compacto` (una).

```powershell
Set-Content -Path "$HOME\.claude\dieciocho.on" -Value "cuerpo" -NoNewline -Encoding utf8
Remove-Item "$HOME\.claude\dieciocho.on"   # apagar
```

## Compartir la skill

Copiar la carpeta completa a `~/.claude/skills/dieciocho/` en el otro
computador. No hay nada más que instalar: los renderizadores son un `.ps1` y
un `.sh` sin dependencias. Con eso, `/dieciocho` ya dibuja.

Si además quiere los verbos o la statusline, que los pida — son los dos pasos
opcionales de arriba.

## Gotchas que ya costaron una vuelta

- **Encoding de salida en Windows**: PowerShell 5.1 escribe en la codepage del
  sistema y convierte los bloques en `?`. Los scripts fuerzan UTF-8 con
  `[Console]::OutputEncoding`. Si aparecen interrogantes, esa línea se cayó.
- **Encoding del archivo**: los glifos se generan con `[char]0xNNNN` (y con
  `printf '\xe2\x96\x80'` en sh) a propósito, para que los scripts queden ASCII
  puros. Si editas uno, no pegues los caracteres literales.
- **macOS trae bash 3.2**: nada de `mapfile` ni de arrays asociativos en el
  `.sh`. Por eso el color va en un `case` y no en un diccionario.
- **Color de 24 bits**: los sprites usan `ESC[38;2;R;G;Bm`. Windows Terminal,
  iTerm2 y la mayoría de los modernos lo soportan; la consola vieja de Windows
  (conhost) no, y ahí se ve plano.
