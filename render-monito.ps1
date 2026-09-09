# Dibuja el monito dieciochero en el terminal.
#
# Cada celda de terminal es el doble de alta que de ancha, asi que un pixel
# cuadrado se hace con medio bloque: color de texto arriba, color de fondo
# abajo. Salen DOS filas de arte por linea de terminal.
#
# Uso:  .\render-monito.ps1                      -> uno al azar de los tres
#       .\render-monito.ps1 -Sprite huaso
#       .\render-monito.ps1 -Sprite bandera -Sangria 2
#
# Sprites: huaso, bandera, volantin  (chupalla negra con cinta blanca)
#          huaso-paja, bandera-paja, volantin-paja  (chupalla de paja)
#          aleatorio  -> sortea entre huaso, bandera y volantin

param(
    [string]$Sprite = "aleatorio",
    [int]$Sangria = 1,
    [switch]$Banner,          # dibuja el monito con las lineas del banner al lado
    [switch]$Cuenta,          # dibuja el monito solo con la cuenta regresiva
    [string]$Modelo = ""      # linea del modelo; la pasa Claude al invocar la skill
)

$ErrorActionPreference = "SilentlyContinue"
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch {}

# --- Paleta (RGB) ---
$paleta = @{
    'c' = @(231, 72, 86)    # coral, el color original del bicho
    'p' = @(217, 164, 65)   # paja
    'a' = @(43,  76, 155)   # azul
    'r' = @(168, 35,  46)   # rojo
    'b' = @(237, 231, 219)  # lana
    'h' = @(107, 98,  89)   # hilo del volantin
    'n' = @(28,  26,  24)   # negro de la chupalla (no negro puro: se despega del fondo)
    'w' = @(237, 231, 219)  # cinta blanca
}

# --- Sprites ---
# Cabeza y patitas conservan la grilla original del bicho: 17 de ancho,
# ojos en las columnas 4 y 12, cuatro patitas.
$sprites = @{
    'huaso' = @(
        '.....nnnnnnn.....',
        '.....wwwwwww.....',
        'nnnnnnnnnnnnnnnnn',
        '..ccccccccccccc..',
        '..cc.ccccccc.cc..',
        'aaaaaaaaaaaaaaaaa',
        '..arrrrrrrrrrra..',
        '....c.c...c.c....'
    )
    'bandera' = @(
        '.....nnnnnnn.....',
        '.....wwwwwww.....',
        'nnnnnnnnnnnnnnnnn',
        '..ccccccccccccc..',
        '..cc.ccccccc.cc..',
        'aabaaabbbbbbbbbbb',
        '..rrrrrrrrrrrrr..',
        '....c.c...c.c....'
    )
    'volantin-negro' = @(
        '.....nnnnnnn......r..',
        '.....wwwwwww.....rrr.',
        'nnnnnnnnnnnnnnnnn.r..',
        '..ccccccccccccc...h..',
        '..cc.ccccccc.cc..h...',
        'aaaaaaaaaaaaaaaaah...',
        '..arrrrrrrrrrra......',
        '....c.c...c.c........'
    )
    'huaso-paja' = @(
        '.....ppppppp.....',
        'ppppppppppppppppp',
        '..ccccccccccccc..',
        '..cc.ccccccc.cc..',
        'aaaaaaaaaaaaaaaaa',
        '..arrrrrrrrrrra..',
        '....c.c...c.c....'
    )
    'bandera-paja' = @(
        '.....ppppppp.....',
        'ppppppppppppppppp',
        '..ccccccccccccc..',
        '..cc.ccccccc.cc..',
        'aabaaabbbbbbbbbbb',
        '..rrrrrrrrrrrrr..',
        '....c.c...c.c....'
    )
    'volantin' = @(
        '.....ppppppp......r..',
        'ppppppppppppppppp.rrr',
        '..ccccccccccccc...r..',
        '..cc.ccccccc.cc...h..',
        'aaaaaaaaaaaaaaaaah...',
        '..arrrrrrrrrrra......',
        '....c.c...c.c........'
    )
}
# El volantin va con chupalla de paja; el negro queda como variante
$sprites['volantin-paja'] = $sprites['volantin']

# "aleatorio" sortea entre los tres que elegimos
if ($Sprite -eq "aleatorio") {
    $Sprite = @('huaso','bandera','volantin') | Get-Random
}

if (-not $sprites.ContainsKey($Sprite)) {
    Write-Error "Sprite desconocido: $Sprite. Opciones: $(($sprites.Keys | Sort-Object) -join ', ')"
    exit 1
}

$grid = $sprites[$Sprite]

# --- Glifos por codigo, para que este archivo quede ASCII puro ---
$e      = [char]27
$reset  = "$e[0m"
$arriba = [string][char]0x2580  # medio bloque superior
$abajo  = [string][char]0x2584  # medio bloque inferior

function Get-Celda {
    param($fila, $col)
    if ($null -eq $fila) { return $null }
    if ($col -ge $fila.Length) { return $null }
    $ch = $fila[$col]
    if ($paleta.ContainsKey([string]$ch)) { return $paleta[[string]$ch] }
    return $null
}

$ancho = 0
foreach ($f in $grid) { if ($f.Length -gt $ancho) { $ancho = $f.Length } }

$margen = " " * $Sangria

# --- Lineas de texto al costado (solo con -Banner) ---
# El sprite tiene 8 filas = 4 lineas de terminal, y el banner de Claude Code
# tiene 3 lineas de texto. La cuarta es la cuenta regresiva.
$textos = @()
if ($Banner -or $Cuenta) {
    $bloque  = [string][char]0x2588  # bloque lleno, para la banderita
    $iTilde  = [string][char]0x00ED  # i con tilde
    $enie    = [string][char]0x00F1  # enie
    $admira  = [string][char]0x00A1  # signo de admiracion abierto

    $cPaja   = "$e[38;2;217;164;65m"
    $cAzul   = "$e[38;2;90;130;220m"
    $cBlanco = "$e[38;2;237;231;219m"
    $cRojo   = "$e[38;2;225;80;90m"
    $cTenue  = "$e[38;2;138;128;120m"

    # Con -Banner replicamos las lineas del banner. Con -Cuenta no: en el
    # arranque el banner de verdad ya salio arriba y repetirlo se ve raro.
    if ($Banner) {
        # Version real, si claude esta en el PATH
        $version = ""
        try {
            $salida = (& claude --version 2>$null)
            if ($salida -match '([0-9]+\.[0-9]+\.[0-9]+)') { $version = $Matches[1] }
        } catch {}
        if ($version) { $textos += "$cBlanco" + "Claude Code v$version" + $reset }

        # La linea del modelo la pasa Claude al invocar la skill: el script no
        # tiene como saber el nombre bonito del modelo de la sesion.
        if ($Modelo) { $textos += "$cTenue$Modelo$reset" }

        $textos += "$cTenue$($PWD.Path)$reset"
    } else {
        # Solo la cuenta: la dejamos a media altura del monito
        $textos += ""
        $textos += ""
    }

    # --- Cuenta regresiva al 18 ---
    $hoy  = (Get-Date).Date
    $anio = $hoy.Year
    $d18  = (Get-Date -Year $anio -Month 9 -Day 18).Date
    # Pasado el 19 ya miramos el dieciocho del proximo anio
    if ($hoy -gt (Get-Date -Year $anio -Month 9 -Day 19).Date) { $d18 = $d18.AddYears(1) }
    $dias = [int]($d18 - $hoy).TotalDays

    if ($dias -gt 1) {
        $frase = "$cPaja" + "faltan " + "$cBlanco$dias$cPaja" + " d" + $iTilde + "as pal 18" + $reset
    } elseif ($dias -eq 1) {
        $frase = "$cPaja" + "ma" + $enie + "ana es el 18" + $reset
    } elseif ($dias -eq 0) {
        $frase = "$cRojo" + $admira + "VIVA CHILE!" + $reset
    } else {
        $frase = "$cPaja" + "sigue el carrete, es 19" + $reset
    }

    $banderita = "$cAzul$bloque$cBlanco$bloque$cRojo$bloque$reset"
    $textos += "$banderita $frase"
}

# Recorremos de dos en dos filas: la de arriba pinta el texto, la de abajo el fondo
$nLinea = 0
for ($y = 0; $y -lt $grid.Count; $y += 2) {
    $filaSup = $grid[$y]
    $filaInf = $null
    if (($y + 1) -lt $grid.Count) { $filaInf = $grid[$y + 1] }

    $linea = $margen
    for ($x = 0; $x -lt $ancho; $x++) {
        $sup = Get-Celda $filaSup $x
        $inf = Get-Celda $filaInf $x

        if ($null -eq $sup -and $null -eq $inf) {
            $linea += " "
        }
        elseif ($null -ne $sup -and $null -eq $inf) {
            $linea += "$e[38;2;$($sup[0]);$($sup[1]);$($sup[2])m$arriba$reset"
        }
        elseif ($null -eq $sup -and $null -ne $inf) {
            $linea += "$e[38;2;$($inf[0]);$($inf[1]);$($inf[2])m$abajo$reset"
        }
        else {
            $linea += "$e[38;2;$($sup[0]);$($sup[1]);$($sup[2])m$e[48;2;$($inf[0]);$($inf[1]);$($inf[2])m$arriba$reset"
        }
    }

    # Cada linea del sprite ocupa exactamente $ancho celdas visibles, asi que
    # el texto queda alineado sin tener que medir los codigos ANSI.
    if ($nLinea -lt $textos.Count -and $textos[$nLinea]) { $linea += "  " + $textos[$nLinea] }
    $nLinea++

    $linea
}
