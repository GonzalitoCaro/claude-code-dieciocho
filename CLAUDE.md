# claude-code-dieciocho

Skill de Claude Code que dibuja el bichito del banner vestido de huaso para el 18 de
septiembre. Repo público de la cuenta personal, fuera de la organización de la agencia.
Se edita desde el computador y desde el celular con Claude Code web.

Como es público, acá no entran rutas personales, correos, nombres de terceros ni nada de
la agencia. Antes de cada commit, mirar el diff con ese ojo.

## Qué hay

Es un plugin de Claude Code: `.claude-plugin/` trae los manifiestos,
`hooks/hooks.json` registra el hook y la skill vive en `skills/dieciocho/`.

| Archivo | Qué es |
|---|---|
| `skills/dieciocho/SKILL.md` | La skill. Es lo que lee Claude Code cuando el usuario escribe `/dieciocho` |
| `README.md` | Instalación y explicación para quien clone el repo |
| `skills/dieciocho/render-monito.ps1` y `render-monito.sh` | Los dos renderizadores, uno por plataforma. Tienen que quedar iguales |
| `skills/dieciocho/sessionstart-monito.ps1` y `sessionstart-monito.sh` | Hook `SessionStart` que pinta el monito al arrancar |
| `skills/dieciocho/prompt-monito.sh` | Hook `UserPromptSubmit`: dibuja el banner cuando el usuario escribe `/dieciocho`. Mide las filas de la terminal y calcula el relleno |
| `skills/dieciocho/gate-dieciocho.sh` | Filtro barato delante del hook anterior. Corre en cada prompt, así que decide con `grep` antes de levantar nada |
| `skills/dieciocho/prender-verbos.sh` y `prender-verbos.ps1` | Hook `SessionStart`: la primera vez escribe `spinnerVerbs` en el `settings.json` del usuario y deja la marca `dieciocho-verbos.hecho`. El `.ps1` es el motor JSON de Windows; en macOS/Linux usa python3, node o jq |
| `skills/dieciocho/medir-filas.ps1` | Solo Windows. Se engancha a la consola del proceso de Claude Code (`CLAUDE_PID`) y devuelve cuántas filas tiene la ventana. Cómo y por qué, en `ESTADO.md` |
| `skills/dieciocho/gate-dieciocho.cmd` y `prompt-monito.ps1` | Reserva. `hooks.json` no los usa: en Windows los hooks también corren en el bash de Git. No tienen el relleno ni la medición del `.sh` |
| `skills/dieciocho/verbos.json` | Los 28 verbos chilenos del spinner |
| `ESTADO.md` | Dónde quedó el trabajo, qué está probado y qué callejones ya se recorrieron. **Leerlo antes de retomar** |

## Reglas del código

- Todo cambio a un sprite o a un color se hace en los dos renderizadores, con las mismas
  letras. Si se toca uno solo, Windows y macOS quedan distintos.
- Los scripts son ASCII puros. Los glifos se generan por código (`[char]0xNNNN` en
  PowerShell, `printf '\xe2\x96\x80'` en sh). Nunca pegar el bloque literal.
- Los `.sh` van siempre con LF, lo fuerza `.gitattributes`. Y tienen que correr en bash 3.2
  (macOS): nada de `mapfile` ni arrays asociativos.
- Los `.ps1` tienen que correr en PowerShell 5.1, no solo en 7.
- Nunca escribir rutas absolutas de un usuario en particular. La skill se comparte.

## Cómo probar

En Linux o macOS, y también en las sesiones en la nube de Claude Code:

```bash
bash skills/dieciocho/render-monito.sh --banner --modelo "Opus 5"
bash skills/dieciocho/render-monito.sh volantin --sangria 2
bash skills/dieciocho/sessionstart-monito.sh
echo '{"prompt":"/dieciocho"}' | bash skills/dieciocho/gate-dieciocho.sh   # debe salir JSON
echo '{"prompt":"hola"}'       | bash skills/dieciocho/gate-dieciocho.sh   # no debe salir nada
```

La salida de los hooks tiene que ser JSON válido. Verificar siempre leyendo
**bytes** y decodificando UTF-8 a mano: si se lee stdin como texto, la codepage
de Windows destroza los bloques y parece un error del hook que no existe.

El `.ps1` no se puede correr en la nube. Si un cambio toca los dos renderizadores, se
prueba el `.sh` y el `.ps1` se revisa a ojo, espejando línea por línea.

## Probado en

Verificado el 9-sep-2026 con contenedores, no a ojo:

| Entorno | bash | awk | Resultado |
|---|---|---|---|
| Debian 13 | 5.2 | mawk 1.3.4 | pasa |
| Debian 13 | 5.2 | GNU awk 5.2 | pasa |
| Imagen `bash:3.2` (la version de bash de macOS) | 3.2.57 | busybox awk | pasa |
| Git Bash en Windows 11 | 5.3 | gawk | pasa |
| `date` estilo BSD, simulado con un shim que rechaza `-d` | — | — | pasa |

Los tres `awk` importan: el escape del ESC para JSON se comporta distinto en cada uno,
y por eso el backslash se fabrica con `sprintf("%c", 92)` en vez de escribirlo literal.

**Lo que NO esta probado**: macOS de verdad. Se simulo la version de bash y el `date` de
BSD, pero no el `awk` ni el `sed` de BSD sobre hardware real. Si alguien lo corre en un
Mac, confirmar y anotarlo aca.

## Flujo de trabajo desde el celular

Las sesiones que se abren desde la app de Claude corren en la nube sobre un clon del
repo y trabajan en una rama `claude/...`. No pueden pushear a `main`: el proxy de git
solo deja pushear a la rama de la sesión.

Por eso el flujo es:

1. Hacer el cambio y probarlo con los comandos de arriba.
2. Commitear, pushear la rama y abrir el PR contra `main`. Sin pedir permiso.
3. El workflow `.github/workflows/auto-merge-claude.yml` mergea el PR solo, con squash, y
   borra la rama. En un minuto el cambio está en `main`.

Si el usuario dice que quiere revisar antes, abrir el PR como draft: los draft no se
mergean solos. Cuando lo apruebe, se marca "Ready for review" y ahí recién se mergea.

Una sesión por cambio. Si el usuario pide dos cosas, van en el mismo PR.

## Estilo

Español chileno directo. En texto nuevo no usar guiones largos como puntuación, solo comas
y puntos. Comillas rectas. Los mensajes de commit en español, una línea, sin punto final.
