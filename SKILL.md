---
name: dieciocho
description: Dibuja el bichito de Claude Code vestido de huaso (chupalla negra, poncho, volantín) y prende o apaga la estética dieciochera — verbos chilenos en el spinner y huaso en la statusline. Úsala cuando el usuario escriba /dieciocho, o pida "el bicho dieciochero", "modo dieciochero", "modo fiestas patrias", "ponme el huaso", "sácame el huaso", "apaga lo del 18", o quiera cambiar de dibujo.
---

# Modo dieciochero

Viste de huaso al bicho pixelado de Claude Code y pone el terminal en modo
18 de septiembre. Todo es local, todo es reversible, y la skill es
autocontenida: se puede copiar a otro computador tal cual.

## Al invocarla sin instrucciones

**No corras ningún comando.** Con el hook `UserPromptSubmit` instalado (ver más
abajo), el banner dieciochero ya se dibujó solo, arriba de tu respuesta, en el
momento en que el usuario escribió `/dieciocho`. Si además lo dibujas tú, sale
"Ran 1 shell command" y el usuario ve el ruido en vez del monito.

Responde una línea corta y nada más. Si el usuario pide otro sprite, ahí sí
corres el renderizador:

**Windows:**
```powershell
& "<BASE>\render-monito.ps1" -Sprite volantin -Banner -Modelo "<MODELO>"
```

**macOS / Linux:**
```bash
bash "<BASE>/render-monito.sh" volantin --banner --modelo "<MODELO>"
```

Ojo igual: la salida de un comando la colapsa Claude Code a "Ran 1 shell
command" y el usuario no ve el dibujo salvo que la expanda. El único canal que
dibuja de verdad en pantalla es el `systemMessage` de un hook.

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

Tres sprites, todos sobre la grilla real del bicho original: 17 columnas, ojos
en las columnas 4 y 12, cuatro patitas.

| Sprite | Qué es |
|---|---|
| `huaso` | Chupalla negra y poncho azul con franja roja |
| `bandera` | Chupalla negra y poncho con la bandera: cantón azul con estrella, blanco al lado, franja roja abajo |
| `volantin` | Chupalla de paja, con un volantín arriba a la derecha y el hilo bajando al poncho |
| `aleatorio` | Sortea entre los tres. Es el que corre por defecto |

Variantes de sombrero: `huaso-paja` y `bandera-paja` con chupalla de paja, y
`volantin-negro` con la chupalla negra.

```powershell
& "<BASE>\render-monito.ps1" -Sprite volantin -Sangria 2
```
```bash
bash "<BASE>/render-monito.sh" volantin --sangria 2
```

### Cómo está dibujado

**Un píxel por celda de terminal**, con `█`. Una celda es el doble de alta que
de ancha, así que los píxeles son rectángulos parados — y esa es justamente la
geometría del bicho original. Los sprites tienen 7 filas: las 5 del bicho más
dos de sombrero.

No uses medio bloque (`▀`) para esto. Da píxeles cuadrados, que se ven más
"correctos" en abstracto pero dejan al monito **achatado a la mitad** al lado
del original. Ya lo probamos y hubo que deshacerlo.

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

## Que el comando dibuje el banner (hook UserPromptSubmit)

Es la pieza clave. El banner de arranque lo pinta el binario y no se puede
tocar; y la salida de un comando la colapsa Claude Code a "Ran 1 shell
command". El unico canal que dibuja de verdad en pantalla es el campo
`systemMessage` de la salida JSON de un hook.

Entonces: un hook `UserPromptSubmit` detecta que el usuario escribio
`/dieciocho` y pinta el banner dieciochero ahi mismo.

**Windows** -- en `~/.claude/settings.json`:

```json
"hooks": {
  "UserPromptSubmit": [
    { "hooks": [ { "type": "command",
        "command": "cmd /c \"C:\\Users\\<TU-USUARIO>\\.claude\\skills\\dieciocho\\gate-dieciocho.cmd\"",
        "timeout": 20 } ] }
  ]
}
```

**macOS / Linux**: el comando es `bash ~/.claude/skills/dieciocho/gate-dieciocho.sh`.

### Por que hay un "gate" y no se llama al script directo

Este hook corre en **cada** prompt, no solo en `/dieciocho`. Levantar
PowerShell cada vez cuesta ~380 ms, que se sienten. El `gate` filtra primero
con `findstr` (~85 ms en Windows) o `grep` (~5 ms en Unix) y recien ahi levanta
lo pesado. El filtro consume el stdin, por eso el script va con `-Directo` y no
lo vuelve a leer.

Para sacarlo, borra el bloque `UserPromptSubmit`.

### Si lo quieres tambien al arrancar

Hay un `sessionstart-monito.ps1` / `.sh` que hace lo mismo en el evento
`SessionStart`. Dibuja el monito con solo la cuenta regresiva, debajo del
banner real. No viene activado.

Aviso: Claude Code le pone a todo mensaje de hook una etiqueta del tipo
`SessionStart:startup says:` y **esa etiqueta no se puede quitar**.

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
- **Los hooks en Windows corren en el bash de Git**, no en PowerShell. Si el
  comando de un hook trae backslashes, bash se los come como escape y sale
  `command not found` con la ruta pegoteada. Las rutas van con slash normal y
  entre comillas, y con `$USERPROFILE` en vez de `$HOME` (en el bash de Git
  `$HOME` es `/c/Users/...`, que PowerShell no sabe leer).
- **Color de 24 bits**: los sprites usan `ESC[38;2;R;G;Bm`. Windows Terminal,
  iTerm2 y la mayoría de los modernos lo soportan; la consola vieja de Windows
  (conhost) no, y ahí se ve plano.
