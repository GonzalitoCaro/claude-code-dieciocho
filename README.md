# dieciocho

Una skill de [Claude Code](https://claude.com/claude-code) que viste de huaso al bichito
del banner y pone el terminal en modo 18 de septiembre.

```
/dieciocho
```

Dibuja uno de tres monitos al azar — chupalla negra con cinta blanca, poncho, volantín —
y opcionalmente cambia los verbos del spinner por chilenismos: en vez de
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
| `bandera` | Chupalla negra y poncho en tres bandas verticales azul, blanco y rojo |
| `volantin` | El huaso con un volantín arriba a la derecha y el hilo bajando al poncho |

Los tres existen también con chupalla de paja: `huaso-paja`, `bandera-paja`, `volantin-paja`.

Para dibujar uno específico, sin pasar por la skill:

```powershell
& "$HOME\.claude\skills\dieciocho\render-monito.ps1" -Sprite volantin
```
```bash
bash ~/.claude/skills/dieciocho/render-monito.sh volantin
```

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

## Lo que no se puede

El bicho del banner de inicio **no se puede reemplazar**: está hardcodeado en el binario
de Claude Code. En el binario, `BannerConfig` resulta ser el banner corporativo de texto
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
- **Color de 24 bits** (`ESC[38;2;R;G;Bm`): Windows Terminal e iTerm2 lo soportan; la
  consola vieja de Windows no, y ahí se ve plano.

## Licencia

MIT. Haz lo que quieras con esto.
