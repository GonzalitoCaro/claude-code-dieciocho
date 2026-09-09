# claude-code-dieciocho

Skill de Claude Code que dibuja el bichito del banner vestido de huaso para el 18 de
septiembre. Repo privado de la cuenta personal, fuera de la organización de la agencia.
Se edita desde el computador y desde el celular con Claude Code web.

## Qué hay

| Archivo | Qué es |
|---|---|
| `SKILL.md` | La skill. Es lo que lee Claude Code cuando el usuario escribe `/dieciocho` |
| `README.md` | Instalación y explicación para quien clone el repo |
| `render-monito.ps1` y `render-monito.sh` | Los dos renderizadores, uno por plataforma. Tienen que quedar iguales |
| `sessionstart-monito.ps1` y `sessionstart-monito.sh` | Hook `SessionStart` que pinta el monito al arrancar |
| `prompt-monito.ps1` y `prompt-monito.sh` | Hook `UserPromptSubmit`: dibuja el banner cuando el usuario escribe `/dieciocho` |
| `gate-dieciocho.cmd` y `gate-dieciocho.sh` | Filtro barato delante del hook anterior. Corre en cada prompt, así que decide con `findstr`/`grep` antes de levantar PowerShell |
| `verbos.json` | Los 28 verbos chilenos del spinner |

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
bash render-monito.sh --banner --modelo "Opus 5"
bash render-monito.sh volantin --sangria 2
bash sessionstart-monito.sh
echo '{"prompt":"/dieciocho"}' | bash gate-dieciocho.sh   # debe salir JSON
echo '{"prompt":"hola"}'       | bash gate-dieciocho.sh   # no debe salir nada
```

La salida de los hooks tiene que ser JSON válido. Verificar siempre leyendo
**bytes** y decodificando UTF-8 a mano: si se lee stdin como texto, la codepage
de Windows destroza los bloques y parece un error del hook que no existe.

El `.ps1` no se puede correr en la nube. Si un cambio toca los dos renderizadores, se
prueba el `.sh` y el `.ps1` se revisa a ojo, espejando línea por línea.

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
