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

- `DIECIOCHO_EMPUJE` (40): líneas en blanco arriba, las que empujan el banner original.
- `DIECIOCHO_EMPUJE_ABAJO` (14): líneas abajo, las que suben el dibujo.
