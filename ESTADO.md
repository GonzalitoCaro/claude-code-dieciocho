# Estado: terminado

El `/dieciocho` dibuja el banner dieciochero y el original desaparece de la vista.
Funciona en Windows, macOS y Linux. Lo que queda acá son los callejones sin salida,
para que nadie los vuelva a recorrer.

## Cómo funciona, en una línea

El banner de arranque no se puede tocar, así que **no se reemplaza: se tapa**. Un hook
`UserPromptSubmit` detecta el comando y devuelve el dibujo en el campo `systemMessage`,
precedido de suficientes líneas en blanco como para que el banner original salga por el
techo de la pantalla.

## Callejones sin salida

No volver a intentarlos:

- **El banner de arranque no se puede reemplazar.** En el binario, `BannerConfig` es el
  banner corporativo de texto (color de fondo, link, tope de 200 caracteres), no el sprite.
- **`terminalSequence`** de los hooks está restringido por allowlist a OSC 0/1/2/9/99/777
  y BEL. No sirve para dibujar.
- **Limpiar la pantalla desde un comando no sirve.** Dentro del TUI el shell no es dueño
  de la pantalla: su salida se captura y se colapsa a "Ran 1 shell command". Por eso el
  dibujo tiene que salir por un hook y no por un comando de la skill.
- **El dibujo no se puede pegar al margen izquierdo.** Quedan ~6 columnas de sangría
  porque el TUI renderiza los mensajes de hook como rama del árbol. Probado y descartado:
  `ESC[1G` (CHA) y retorno de carro al inicio de cada línea, solos y juntos. El TUI los
  filtra al componer el cuadro.
- **La etiqueta `UserPromptSubmit says:` no se puede quitar.** Claude Code se la pone a
  todo mensaje de hook. En la práctica no molesta: el relleno de arriba la empuja fuera
  de la vista junto con el banner original.
- **Los hooks en Windows corren en el bash de Git**, no en `cmd` ni en PowerShell. Nada
  de backslashes en el comando: bash se los come como escape y la ruta llega partida.
  Tampoco existe `cmd` en el enum de `shell` de un hook (solo `bash` y `powershell`).

## Trampas del código que ya costaron una vuelta

- **El filtro tiene que mirar solo el campo `prompt`**, no el JSON entero. El JSON trae el
  `cwd`, y si la carpeta del proyecto tiene "dieciocho" en el nombre el banner aparece en
  cada mensaje.
- **El relleno de líneas en blanco no se arma con `$(...)`**: la sustitución de comandos
  borra todos los saltos del final y queda vacío. Se acumula dentro de la variable.
- **Las líneas de relleno de abajo llevan un espacio**, no van vacías: `awk` descarta el
  último registro si el texto termina en saltos pelados.
- **Escapar el ESC para JSON**: no se puede con `sed` ni con el reemplazo de `gsub` (la
  secuencia backslash-u significa otra cosa según la implementación), ni pasando el
  literal backslash-n por `printf` (awk lo convierte en salto real). El backslash se
  fabrica con `sprintf("%c", 92)`.
- **PowerShell 5.1 escribe en la codepage del sistema** y convierte los bloques en `?`.
  Hay que forzar `[Console]::OutputEncoding`.
- **Verificar la salida de los hooks leyendo bytes** y decodificando UTF-8 a mano. Si se
  lee como texto, la codepage de Windows destroza los bloques y parece un error que no
  existe.
- **Sin emoji.** La bandera chilena se arma con dos indicadores regionales que Windows
  Terminal no compone: deja una `c` suelta. Para adornos, `★` y bloques de color.

## Cómo probar sin abrir una terminal nueva

```bash
echo '{"prompt":"/dieciocho"}' | bash skills/dieciocho/gate-dieciocho.sh   # sale JSON
echo '{"prompt":"hola"}'       | bash skills/dieciocho/gate-dieciocho.sh   # no sale nada
```

## Lo que se puede afinar sin tocar código

Los rellenos se calculan a partir de las filas de la terminal: arriba tantas líneas como
filas, abajo las filas menos 19 (7 del arte, 2 saltos entre mensajes, unas 10 de la zona
del prompt y una fila en blanco encima del huaso). Con un número fijo el huaso quedaba a
media altura en una ventana chica y pegado arriba con un hueco en una maximizada.

- `DIECIOCHO_FILAS`: fuerza la altura medida. Sirve para probar (`DIECIOCHO_FILAS=24`) y
  como salida si la medición falla.
- `DIECIOCHO_EMPUJE`: líneas en blanco arriba, las que empujan el banner original.
- `DIECIOCHO_EMPUJE_ABAJO`: líneas abajo, las que suben el dibujo.

Sin medida, quedan los fijos de antes: 40 arriba y 14 abajo.

**Cómo se mide.** Un hook no hereda la terminal. En Windows, Claude Code lo lanza sin
consola, y cualquier proceso que pregunte por "la consola" recibe una oculta nueva de
120x30, el tamaño por defecto de Windows: `$Host.UI.RawUI.WindowSize.Height` devuelve 30
siempre y parece un valor real (costó un pantallazo darse cuenta). `[Console]::WindowHeight`
directamente falla con "Controlador no válido". Lo que sirve es `medir-filas.ps1`:
`FreeConsole`, `AttachConsole` al PID que llega en `CLAUDE_PID`, abrir `CONOUT$` y leer
`srWindow` con `GetConsoleScreenBufferInfo`. `srWindow`, no `dwSize`: `dwSize` es el buffer
de scroll, 9001 líneas en Windows Terminal. En macOS y Linux, `stty size </dev/tty`. No
usar `tput lines`: sin tty inventa 24.

Dos trampas de PowerShell 5.1 en ese script: `Add-Type -PassThru` devuelve la clase y las
structs anidadas en un arreglo, así que hay que tomar `[Dieciocho.Consola]` por nombre; y
`0xC0000000` se lee como Int32 negativo, el acceso de `CreateFile` va en decimal.

**Cómo probar la medición sin abrir una terminal nueva.** Desde una sesión de Claude Code,
`CLAUDE_PID` es el proceso interactivo, y `powershell -File skills/dieciocho/medir-filas.ps1
-ProcesoId $CLAUDE_PID` tiene que dar las filas de esa ventana. Ojo: si se prueba con
`claude -p` lanzado desde un tool de Bash, da 30, porque ese `claude -p` ya nació sin
consola. Eso no pasa en la sesión interactiva de verdad.
