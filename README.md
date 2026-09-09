# dieciocho

Una skill de [Claude Code](https://claude.com/claude-code) que viste de huaso al bichito
del banner y pone el terminal en modo 18 de septiembre.

```
/dieciocho
```

Dibuja uno de tres monitos al azar — chupalla negra con cinta blanca, poncho, volantín — con
las líneas del banner al lado y la cuenta regresiva al 18:

```
▀▀▀▀▀      Claude Code v2.1.266
▀▀▀▀▀▀▀    Opus 5 (1M context) with high effort
▀▀▀▀▀▀▀    ~/mi-proyecto
 ▀▀▀ ▀▀    ███ faltan 9 días pal 18
```

Y opcionalmente cambia los verbos del spinner por chilenismos: en vez de
*Bloviating…* te sale **Rayueleando…**, **Anticucheando…**, **Terremoteando…**

## Instalar

Clona el repo directo en tu carpeta de skills. Es todo lo que hay que hacer.

**Windows (PowerShell):**
```powershell
git clone https://github.com/GonzalitoCaro/claude-code-dieciocho "$HOME\.claude\skills\dieciocho"
```

**macOS / Linux:**
```bash
git clone https://github.com/GonzalitoCaro/claude-code-dieciocho ~/.claude/skills/dieciocho
```

Abre Claude Code y escribe `/dieciocho`. No hay dependencias: los renderizadores son
un `.ps1` y un `.sh` pelados.

Para actualizar, `git pull` en esa misma carpeta. Para desinstalar, bórrala.

## Los tres monitos

Todos respetan la grilla del bicho original — 17 columnas, ojos en las columnas 4 y 12,
cuatro patitas — y le agregan sombrero y manta.

| Sprite | Qué es |
|---|---|
| `huaso` | Chupalla negra y poncho azul con franja roja |
| `bandera` | Chupalla negra y poncho con la bandera: cantón azul con estrella, blanco al lado y franja roja abajo |
| `volantin` | Chupalla de paja, con un volantín arriba a la derecha y el hilo bajando al poncho |

Variantes de sombrero: `huaso-paja` y `bandera-paja` con chupalla de paja, y `volantin-negro`
con la chupalla negra.

Para dibujar uno específico, sin pasar por la skill:

```powershell
& "$HOME\.claude\skills\dieciocho\render-monito.ps1" -Sprite volantin
& "$HOME\.claude\skills\dieciocho\render-monito.ps1" -Banner -Modelo "Opus 5"
```
```bash
bash ~/.claude/skills/dieciocho/render-monito.sh volantin
bash ~/.claude/skills/dieciocho/render-monito.sh --banner --modelo "Opus 5"
```

La versión y la ruta las saca el script solo; la línea del modelo se la pasa Claude al
invocar la skill, porque el script no tiene cómo saber el nombre de la sesión.

## Cómo está dibujado

Una celda de terminal es el doble de alta que de ancha, así que un píxel cuadrado no se
hace con `█` sino con `▀`: color de texto arriba, color de fondo abajo. Salen **dos filas
de arte por línea de terminal**, y por eso los sprites tienen 8 filas — cuatro líneas
exactas, sin media línea desperdiciada.

Los sprites se escriben como texto plano, una letra por color:

```
.....nnnnnnn.....      c  coral (el color original del bicho)
.....wwwwwww.....      p  paja
nnnnnnnnnnnnnnnnn      a  azul
..ccccccccccccc..      r  rojo
..cc.ccccccc.cc..      b  lana
aaaaaaaaaaaaaaaaa      h  hilo del volantín
..arrrrrrrrrrra..      n  negro de la chupalla
....c.c...c.c....      w  cinta blanca
                       .  fondo
```

Si quieres agregar uno, edítalo en los dos renderizadores con las mismas letras.

## Los verbos

Están en `verbos.json`. Son 28 y reemplazan a los de fábrica. Para prenderlos, copia ese
objeto como la clave `spinnerVerbs` de tu `~/.claude/settings.json`:

```json
"spinnerVerbs": { "mode": "replace", "verbs": ["Dieciocheando", "Cuequeando", "..."] }
```

`replace` deja solo los chilenos; `append` los mezcla con los originales. Se aplican al
toque, sin reiniciar. Para apagarlos, saca la clave.

## Que salga solo, al arrancar

El dibujo del banner no se puede reemplazar, pero un hook `SessionStart` puede
pintar debajo: Claude Code muestra al usuario el campo `systemMessage` de la
salida JSON de un hook, y ese es el unico canal que dibuja en pantalla al
arrancar. El monito queda justo bajo la ruta, con la cuenta regresiva.

Agrega esto a `~/.claude/settings.json`.

**Windows:**
```json
"hooks": {
  "SessionStart": [
    { "hooks": [ { "type": "command",
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$USERPROFILE/.claude/skills/dieciocho/sessionstart-monito.ps1\"",
        "timeout": 20 } ] }
  ]
}
```

**macOS / Linux:**
```json
"hooks": {
  "SessionStart": [
    { "hooks": [ { "type": "command",
        "command": "bash \"$HOME/.claude/skills/dieciocho/sessionstart-monito.sh\"",
        "timeout": 20 } ] }
  ]
}
```

**Nunca pongas backslashes en el comando de un hook.** En Windows los hooks igual
corren dentro del bash de Git, y bash se come el backslash como escape: una ruta
`C:\Users\...` le llega al comando como `C:Users...` y el arranque queda con un
`command not found` en pantalla. Por eso la ruta va con slash normal y entre
comillas. Y por eso va `$USERPROFILE` y no `$HOME`: en el bash de Git `$HOME` es
`/c/Users/...`, que PowerShell no sabe leer.

Para sacarlo, borra el bloque `SessionStart`.

## Lo que no se puede

El bicho del banner de inicio **no se puede reemplazar**: está hardcodeado en el binario
de Claude Code. Lo más cerca que se llega es el hook de arriba, que dibuja el huaso
*debajo* del banner original. En el binario, `BannerConfig` resulta ser el banner corporativo de texto
—color de fondo, link, 200 caracteres— y no tiene nada que ver con el sprite.

Así que el monito no se reemplaza, se dibuja: la skill lo pinta cuando la invocas, y la
statusline es el único lugar donde puede quedar fijo.

## Detalles que costaron una vuelta

- **Windows**: PowerShell 5.1 escribe en la codepage del sistema y convierte los bloques
  en `?`. El script fuerza UTF-8 con `[Console]::OutputEncoding`.
- **Los glifos se generan por código** (`[char]0xNNNN`, `printf '\xe2\x96\x80'`) para que
  los scripts queden ASCII puros y no dependan del encoding con que se lean.
- **macOS trae bash 3.2**: nada de `mapfile` ni arrays asociativos. Por eso el color va en
  un `case`.
- **Los hooks en Windows corren en el bash de Git**, no en PowerShell: si el
  comando trae backslashes, bash se los come y sale
  `C:PROGRA~1Gitbinbash.exe: command not found`. Rutas con slash y entre comillas.
- **Color de 24 bits** (`ESC[38;2;R;G;Bm`): Windows Terminal e iTerm2 lo soportan; la
  consola vieja de Windows no, y ahí se ve plano.

## Licencia

MIT. Haz lo que quieras con esto.
