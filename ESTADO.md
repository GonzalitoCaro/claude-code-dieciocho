# Estado: falta confirmar el hook del comando en el PC

Ultima sesion: 9-sep-2026, desde el telefono. La causa del silencio ya esta
encontrada; falta pegar el comando corregido en el PC y mirar.

## Lo que ya funciona (probado, no suponer)

- **El canal existe y renderiza a color.** Un hook `SessionStart` con
  `sessionstart-monito.ps1` dibujo el monito con todos sus colores debajo del banner.
  Confirmado con pantallazo. O sea: `systemMessage` **si** acepta codigos ANSI.
- **Los renderizadores estan bien.** `render-monito.ps1` y `render-monito.sh` dan
  salida identica, con la geometria del original: una fila de arte por linea, 7 filas.
- **El gate produce JSON valido.** `echo '{"prompt":"/dieciocho"}' | bash
  gate-dieciocho.sh` saca 3131 bytes de JSON que parsea, con 2262 caracteres de
  arte adentro. Con un prompt cualquiera saca 0 bytes.

## La causa del silencio: bash se come los backslashes

Los hooks en Windows **no corren por `cmd` ni por PowerShell: corren dentro del
bash de Git**. El pantallazo de la prueba del 9-sep lo dice textual:

```
UserPromptSubmit hook error
Failed with non-blocking status code: /usr/bin/bash: line 1: C:PROGRA~1Gitbinbash.exe: command not found
```

El comando que estaba en `settings.json` era:

```
C:\PROGRA~1\Git\bin\bash.exe C:\Users\GONZAL~1\CLAUDE~1\skills\DIECIO~1\GATE-D~1.SH
```

Bash lee cada backslash como escape y lo borra, asi que el ejecutable le llega
como `C:PROGRA~1Gitbinbash.exe`. Reproducido:

```
$ bash -c 'echo C:\PROGRA~1\Git\bin\bash.exe'
C:PROGRA~1Gitbinbash.exe
```

Como el hook ya corre en bash, no hay que invocar bash por ruta absoluta ni
pasar por el `.cmd`: el comando es el mismo de macOS y Linux.

## Que pegar en `~/.claude/settings.json` (pendiente, en el PC)

```json
"hooks": {
  "UserPromptSubmit": [
    { "hooks": [ { "type": "command",
        "command": "bash \"$HOME/.claude/skills/dieciocho/gate-dieciocho.sh\"",
        "timeout": 20 } ] }
  ]
}
```

Sin backslashes, con comillas, y con `$HOME` (no `$USERPROFILE`): el que lee esa
ruta es bash, y en el bash de Git `$HOME` ya es `/c/Users/...`. `$USERPROFILE`
va solo cuando el comando es `powershell -File`, que es el caso del hook
`SessionStart` del README.

Terminal nueva, escribir `/dieciocho`, y tiene que salir el banner dieciochero.

## Si con eso todavia no dibuja

En este orden:

1. **Sacar la llamada a `claude --version` del modo `--banner`.** El renderizador
   la usa para armar la primera linea. Es un binario de 219 MB y dentro de un
   hook puede estar demorando o colgandose. Se nota facil: si `/dieciocho` se
   demora y no sale nada, es eso.
2. **Confirmar que Claude Code tomo el hook**, reemplazando el comando por uno
   trivial que siempre imprima un `systemMessage` fijo. Si tampoco sale, el
   problema es la carga del hook y no el dibujo.
3. Revisar si Claude Code deja registro de fallas de hooks en algun log.

## Callejones sin salida ya recorridos

No volver a intentarlos:

- **El banner no se puede reemplazar.** `BannerConfig` en el binario es el banner
  corporativo de texto (color de fondo, link, tope de 200 caracteres), no el sprite.
- **`terminalSequence`** de los hooks esta restringido por allowlist a OSC 0/1/2/9/99/777
  y BEL. No sirve para dibujar.
- **Limpiar la pantalla desde un comando no sirve**: dentro del TUI el shell no es dueño
  de la pantalla, su salida se captura y se colapsa a "Ran 1 shell command".
- **`cmd /c` con una ruta entre comillas** se rompe como comando de hook: quedan
  comillas anidadas, arranca un cmd interactivo que escupe el banner de Windows y
  se come el stdin. Con el hook corriendo en bash el `.cmd` ya no hace falta;
  queda en el repo por si alguna version vuelve a ejecutar los hooks por `cmd`.
- **El `bash` del PATH de Windows es el de WSL** y en esta maquina no tiene distro:
  falla con `execvpe(/bin/bash)`. Ojo que eso pasa desde `cmd`; **desde el hook no
  aplica**, porque ahi el `bash` que se resuelve es el de Git, que es quien esta
  corriendo el comando.
- **El enum de `shell` en un hook es `bash` / `powershell`.** No existe `cmd`.

## Costo que hay que respetar

El hook corre en **cada** prompt, no solo en `/dieciocho`. Por eso existe el gate: filtra
con `grep` (~119 ms con el bash de Git) antes de levantar nada pesado. Llamar directo a
PowerShell costaba ~380 ms por mensaje, que se sienten. Cualquier solucion nueva tiene
que mantener ese filtro barato adelante.
