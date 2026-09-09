# Dibuja el monito dieciochero en el terminal.
#
# GEOMETRIA: el bicho original de Claude Code usa un pixel por celda de
# terminal, y una celda es el doble de alta que de ancha. Osea sus pixeles son
# rectangulos parados, no cuadrados. Aca hacemos lo mismo -- una fila de arte
# por linea -- para que el huaso tenga las mismas proporciones. (Con medio
# bloque los pixeles salen cuadrados y el monito queda achatado a la mitad.)
#
# Uso:  .\render-monito.ps1                      -> uno al azar de los tres
#       .\render-monito.ps1 -Sprite volantin
#       .\render-monito.ps1 -Cuenta              -> con la cuenta regresiva
#       .\render-monito.ps1 -Banner -Modelo "Opus 5"
#
# Sprites: huaso, bandera, volantin, aleatorio
#          huaso-paja, bandera-paja, volantin-negro

param(
    [string]$Sprite = "aleatorio",
    [int]$Sangria = 1,
    [switch]$Banner,          # replica las lineas del banner al lado
    [switch]$Cuenta,          # solo la cuenta regresiva al lado
    [string]$Modelo = ""      # linea del modelo; la pasa Claude al invocar la skill
)

$ErrorActionPreference = "SilentlyContinue"
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch {}

# --- Paleta (RGB) ---
# El negro de la chupalla NO es negro puro: sobre el fondo #0C0C0C del terminal
# un negro real desaparece y solo se ve la cinta blanca flotando.
$paleta = @{
    'c' = @(231, 72, 86)    # coral, el color original del bicho
    'p' = @(217, 164, 65)   # paja
    'a' = @(43,  76, 155)   # azul
    'r' = @(168, 35,  46)   # rojo
    'b' = @(237, 231, 219)  # lana
    'h' = @(107, 98,  89)   # hilo del volantin
    'n' = @(53,  48,  43)   # negro de la chupalla
    'w' = @(237, 231, 219)  # cinta blanca
}

# --- Sprites ---
# 17 columnas, ojos en las columnas 4 y 12, cuatro patitas: la grilla exacta
# del bicho original, con dos filas de sombrero encima.
$sprites = @{
    'huaso' = @(
        '.....nnnnnnn.....',
        'nnnnwwwwwwwwwnnnn',
        '..ccccccccccccc..',
        '..cc.ccccccc.cc..',
        'aaaaaaaaaaaaaaaaa',
        '..arrrrrrrrrrra..',
        '....c.c...c.c....'
    )
    'bandera' = @(
        '.....nnnnnnn.....',
        'nnnnwwwwwwwwwnnnn',
        '..ccccccccccccc..',
        '..cc.ccccccc.cc..',
        'aabaaabbbbbbbbbbb',
        '..rrrrrrrrrrrrr..',
        '....c.c...c.c....'
    )
    'volantin' = @(
        '.....ppppppp.......r.',
        'ppppppppppppppppp.rrr',
        '..ccccccccccccc....r.',
        '..cc.ccccccc.cc...h..',
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
    'volantin-negro' = @(
        '.....nnnnnnn.......r.',
        'nnnnwwwwwwwwwnnnn.rrr',
        '..ccccccccccccc....r.',
        '..cc.ccccccc.cc...h..',
        'aaaaaaaaaaaaaaaaah...',
        '..arrrrrrrrrrra......',
        '....c.c...c.c........'
    )
}
$sprites['volantin-paja'] = $sprites['volantin']

if ($Sprite -eq "aleatorio") {
    $Sprite = @('huaso','bandera','volantin') | Get-Random
}
if (-not $sprites.ContainsKey($Sprite)) {
    Write-Error "Sprite desconocido: $Sprite. Opciones: $(($sprites.Keys | Sort-Object) -join ', ')"
    exit 1
}
$grid = $sprites[$Sprite]

# --- Glifos por codigo, para que este archivo quede ASCII puro ---
$e       = [char]27
$reset   = "$e[0m"
$bloque  = [string][char]0x2588  # bloque lleno: un pixel = una celda
$estrella= [string][char]0x2605  # estrella de la bandera
$iTilde  = [string][char]0x00ED
$enie    = [string][char]0x00F1
$admira  = [string][char]0x00A1

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

# --- Texto al costado, indexado por fila del sprite ---
$textos = @{}
if ($Banner -or $Cuenta) {
    $cPaja   = "$e[38;2;217;164;65m"
    $cBlanco = "$e[38;2;237;231;219m"
    $cRojo   = "$e[38;2;225;80;90m"
    $cTenue  = "$e[38;2;138;128;120m"

    if ($Banner) {
        $version = ""
        try {
            $salida = (& claude --version 2>$null)
            if ($salida -match '([0-9]+\.[0-9]+\.[0-9]+)') { $version = $Matches[1] }
        } catch {}
        $fila = 1
        if ($version) { $textos[$fila] = "$cBlanco" + "Claude Code v$version" + $reset; $fila++ }
        if ($Modelo)  { $textos[$fila] = "$cTenue$Modelo$reset"; $fila++ }
        $textos[$fila] = "$cTenue$($PWD.Path)$reset"
        $filaCuenta = $fila + 2
    } else {
        # Solo la cuenta: a media altura del monito
        $filaCuenta = 4
    }

    $hoy  = (Get-Date).Date
    $anio = $hoy.Year
    $d18  = (Get-Date -Year $anio -Month 9 -Day 18).Date
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

    # Estrella sola: tres bloques azul/blanco/rojo se leen como Francia.
    $textos[$filaCuenta] = "$cBlanco$estrella$reset $frase"
}

# --- Dibujo: una fila de arte por linea de terminal ---
for ($y = 0; $y -lt $grid.Count; $y++) {
    $fila = $grid[$y]
    $linea = $margen
    for ($x = 0; $x -lt $ancho; $x++) {
        $col = Get-Celda $fila $x
        if ($null -eq $col) { $linea += " " }
        else { $linea += "$e[38;2;$($col[0]);$($col[1]);$($col[2])m$bloque$reset" }
    }
    if ($textos.ContainsKey($y)) { $linea += "  " + $textos[$y] }
    $linea
}
