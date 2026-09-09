# Hook SessionStart: dibuja el monito dieciochero debajo del banner de arranque.
#
# El banner del bicho esta hardcodeado en el binario y no se puede reemplazar.
# El unico canal que pinta en pantalla al arrancar es el campo systemMessage
# de la salida JSON de un hook, asi que por ahi va.
#
# Si algo falla, no imprimimos nada: un hook que escupe basura sale en pantalla
# como "SessionStart:startup hook error" y molesta en cada arranque.

$ErrorActionPreference = "Stop"
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
    $base   = Split-Path -Parent $MyInvocation.MyCommand.Path
    $lineas = & (Join-Path $base "render-monito.ps1") -Cuenta
    if (-not $lineas) { exit 0 }
    @{ systemMessage = ($lineas -join "`n") } | ConvertTo-Json -Compress
} catch {
    exit 0
}
