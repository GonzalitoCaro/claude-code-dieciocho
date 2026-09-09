# Motor de Windows para prender-verbos.sh: agrega spinnerVerbs al settings.json
# y escribe el resultado en -Salida. No toca el original: el .sh lo reemplaza
# solo si esto termino bien. Ver las reglas en prender-verbos.sh.
#
# Trampas de PowerShell 5.1 que ya costaron una vuelta:
# - ConvertTo-Json corta a 2 niveles por defecto y deja "System.Object[]" en
#   vez del contenido. Hay que pasar -Depth alto.
# - Get-Content -Raw lee bien con o sin BOM, pero al escribir hay que usar
#   UTF8Encoding($false) o queda con BOM, y Claude Code no lo quiere.
# - ConvertTo-Json escapa < > & ' como < etc. Es JSON valido igual.

param(
    [Parameter(Mandatory = $true)][string]$Settings,
    [Parameter(Mandatory = $true)][string]$Verbos,
    [Parameter(Mandatory = $true)][string]$Salida
)

$ErrorActionPreference = "Stop"
try {
    # OJO: no llamar $verbos a esta variable. PowerShell no distingue mayusculas
    # y seria el mismo parametro [string]$Verbos: el objeto se convierte a texto
    # y en el settings.json queda "@{mode=replace; verbs=System.Object[]}".
    $objVerbos = Get-Content -LiteralPath $Verbos -Raw -Encoding UTF8 | ConvertFrom-Json
    if (Test-Path -LiteralPath $Settings) {
        $texto = Get-Content -LiteralPath $Settings -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($texto)) { $texto = "{}" }
        $cfg = $texto | ConvertFrom-Json
        if ($cfg -isnot [System.Management.Automation.PSCustomObject]) { exit 1 }
    } else {
        $cfg = New-Object PSObject
    }
    $cfg | Add-Member -MemberType NoteProperty -Name "spinnerVerbs" -Value $objVerbos -Force
    $json = ($cfg | ConvertTo-Json -Depth 64) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($Salida, $json + "`n", (New-Object System.Text.UTF8Encoding $false))
    exit 0
} catch {
    exit 1
}
