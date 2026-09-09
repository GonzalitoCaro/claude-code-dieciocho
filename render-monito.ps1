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
    [int]$Sangria = 1
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
        'aaaaaabbbbbrrrrrr',
        '..aaaabbbbbrrrr..',
        '....c.c...c.c....'
    )
    'volantin' = @(
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
        'aaaaaabbbbbrrrrrr',
        '..aaaabbbbbrrrr..',
        '....c.c...c.c....'
    )
    'volantin-paja' = @(
        '.....ppppppp......r..',
        'ppppppppppppppppp.rrr',
        '..ccccccccccccc...r..',
        '..cc.ccccccc.cc...h..',
        'aaaaaaaaaaaaaaaaah...',
        '..arrrrrrrrrrra......',
        '....c.c...c.c........'
    )
}

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

# Recorremos de dos en dos filas: la de arriba pinta el texto, la de abajo el fondo
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
    $linea
}
