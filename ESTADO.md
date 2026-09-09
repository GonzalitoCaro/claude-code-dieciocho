# Estado: el hook del comando todavía no dibuja

Última sesión: 9-sep-2026, desde el computador. Se corta acá para seguir desde el
teléfono.

## Lo que ya funciona (probado, no suponer)

- **El canal existe y renderiza a color.** Un hook `SessionStart` con
  `sessionstart-monito.ps1` dibujó el monito con todos sus colores debajo del banner.
  Confirmado con pantallazo. O sea: `systemMessage` **sí** acepta códigos ANSI.
- **Los renderizadores están bien.** `render-monito.ps1` y `render-monito.sh` dan
  salida idéntica, con la geometría del original: una fila de arte por línea, 7 filas.
- **El gate produce JSON válido.** Corriendo a mano el comando exacto que quedó en
  `settings.json`, salen 3038 caracteres de JSON válido cuando el prompt es
  `/dieciocho`, y 0 bytes cuando no lo es.

## Lo que falla

Con el hook `UserPromptSubmit` instalado, al escribir `/dieciocho` en una terminal
nueva **no aparece nada**: ni el monito, ni un error de hook. Silencio total.

Comando que quedó en `~/.claude/settings.json` (rutas cortas 8.3 a propósito, ver
abajo):

```
C:\PROGRA~1\Git\bin\bash.exe C:\Users\GONZAL~1\CLAUDE~1\skills\DIECIO~1\GATE-D~1.SH
```

## Callejones sin salida ya recorridos

No volver a intentarlos:

- **El banner no se puede reemplazar.** `BannerConfig` en el binario es el banner
  corporativo de texto (color de fondo, link, tope de 200 caracteres), no el sprite.
- **`terminalSequence`** de los hooks está restringido por allowlist a OSC 0/1/2/9/99/777
  y BEL. No sirve para dibujar.
- **Limpiar la pantalla desde un comando no sirve**: dentro del TUI el shell no es dueño
  de la pantalla, su salida se captura y se colapsa a "Ran 1 shell command".
- **`cmd /c` con una ruta entre comillas** se rompe como comando de hook: Claude Code ya
  ejecuta los hooks a través de `cmd`, queda un cmd dentro de otro y las comillas
  anidadas arrancan un cmd interactivo que escupe el banner de Windows y se come el
  stdin. Por eso las rutas van cortas 8.3, sin comillas.
- **El `bash` del PATH de Windows es el de WSL** y en esta máquina no tiene distro: falla
  con `execvpe(/bin/bash)`. Hay que apuntar al de Git con ruta absoluta.
- **El enum de `shell` en un hook es `bash` / `powershell`.** No existe `cmd`.

## Qué probar, en este orden

1. **Confirmar que Claude Code tomó el hook.** Reemplazar el comando por uno trivial que
   siempre imprima un systemMessage fijo, y abrir una terminal nueva. Si tampoco sale, el
   problema es que el hook no se está cargando, y no tiene nada que ver con el dibujo.
2. **Sacar la llamada a `claude --version` del modo `--banner`.** El renderizador la usa
   para armar la primera línea. Es un binario de 219 MB y dentro de un hook puede estar
   demorando o colgándose; el resultado sería exactamente esto: silencio. Es la hipótesis
   más probable.
3. **Probar con la ruta larga entre comillas** en vez de la corta 8.3, por si el ejecutor
   no resuelve rutas 8.3.
4. Revisar si Claude Code deja registro de fallas de hooks en algún log.

## Cómo probar sin abrir una terminal nueva cada vez

```bash
echo '{"prompt":"/dieciocho"}' | bash gate-dieciocho.sh   # debe salir JSON
echo '{"prompt":"hola"}'       | bash gate-dieciocho.sh   # no debe salir nada
```

Verificar el JSON leyendo **bytes** y decodificando UTF-8 a mano. Si se lee como texto,
la codepage de Windows destroza los bloques y parece un error del hook que no existe.

## Costo que hay que respetar

El hook corre en **cada** prompt, no solo en `/dieciocho`. Por eso existe el gate: filtra
con `grep` (~119 ms con Git Bash) antes de levantar nada pesado. Llamar directo a
PowerShell costaba ~380 ms por mensaje, que se sienten. Cualquier solución nueva tiene
que mantener ese filtro barato adelante.
