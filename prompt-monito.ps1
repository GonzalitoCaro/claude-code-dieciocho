# Hook UserPromptSubmit: al escribir /dieciocho, simula el banner.
#
# El banner de arranque lo pinta el binario y no se puede tocar. Lo que si se
# puede es dibujar uno propio abajo: Claude Code muestra al usuario el campo
# systemMessage de la salida JSON de un hook. Escribiendo /dieciocho aparece
# el banner dieciochero completo, como si se hubiera reemplazado.
#
# OJO: este hook corre en CADA prompt, asi que sale temprano y en silencio
# cuando no es el comando. Todo lo caro pasa solo cuando calza.

param([switch]$Directo)   # -Directo: el filtro barato ya decidio, no releer stdin

$ErrorActionPreference = "Stop"
try {
    if (-not $Directo) {
        $entrada = [Console]::In.ReadToEnd()
        if (-not $entrada) { exit 0 }
        $texto = ($entrada | ConvertFrom-Json).prompt
        if (-not $texto) { exit 0 }
        if ($texto.Trim() -notmatch '^/?dieciocho\b') { exit 0 }
    }

    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
    $base = Split-Path -Parent $MyInvocation.MyCommand.Path

    # Armamos la linea del modelo leyendo la configuracion del usuario, para
    # que diga lo mismo que el banner de verdad sin tener que hardcodearlo.
    $modelo = ""
    try {
        $cfg = Get-Content (Join-Path $HOME ".claude\settings.json") -Raw | ConvertFrom-Json
        $id = [string]$cfg.model
        if ($id) {
            $nombre = switch -Regex ($id) {
                '^opus'   { "Opus 5" }
                '^sonnet' { "Sonnet 5" }
                '^haiku'  { "Haiku 4.5" }
                '^fable'  { "Fable 5.1" }
                default   { $id }
            }
            if ($id -match '\[1m\]') { $nombre += " (1M context)" }
            $esfuerzo = ($cfg.modelSettings.PSObject.Properties |
                         ForEach-Object { $_.Value.effortLevel } |
                         Where-Object { $_ } | Select-Object -First 1)
            if ($esfuerzo) { $nombre += " with $esfuerzo effort" }
            $modelo = $nombre
        }
    } catch {}

    $lineas = & (Join-Path $base "render-monito.ps1") -Banner -Modelo $modelo
    if (-not $lineas) { exit 0 }
    # additionalContext se lo lleva Claude como contexto, no el usuario. Con eso
    # la skill sabe que el hook esta instalado y ya dibujo, y no vuelve a dibujar.
    $aviso = "El hook dieciocho ya dibujo el banner en pantalla. No corras ningun comando para dibujarlo de nuevo."
    @{
        systemMessage      = ($lineas -join "`n")
        hookSpecificOutput = @{ hookEventName = "UserPromptSubmit"; additionalContext = $aviso }
    } | ConvertTo-Json -Compress
} catch {
    exit 0
}
