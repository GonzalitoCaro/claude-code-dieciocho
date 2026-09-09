# Cuantas filas tiene la terminal donde corre Claude Code. Lo llama
# prompt-monito.sh en Windows.
#
# Un hook no hereda la consola: Claude Code lo lanza sin ventana, y PowerShell
# se inventa una consola oculta con el tamano por defecto de Windows, 120x30.
# Por eso $Host.UI.RawUI y [Console] devuelven 30 siempre, sea cual sea la
# ventana de verdad. La salida es soltar esa consola y engancharse a la del
# proceso de Claude Code, que llega en la variable de entorno CLAUDE_PID, y
# preguntarle a esa por su ventana visible (srWindow, no dwSize: dwSize es el
# buffer de scroll, 9001 lineas en Windows Terminal).
#
# Imprime un numero, o nada si no se pudo.

param([int]$ProcesoId = 0)

$ErrorActionPreference = "Stop"
try {
    if ($ProcesoId -le 0) { exit 0 }

    $firma = @'
[DllImport("kernel32.dll", SetLastError = true)] public static extern bool FreeConsole();
[DllImport("kernel32.dll", SetLastError = true)] public static extern bool AttachConsole(uint dwProcessId);
[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr CreateFile(string lpFileName, uint dwDesiredAccess, uint dwShareMode, IntPtr lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, IntPtr hTemplateFile);
[StructLayout(LayoutKind.Sequential)] public struct COORD { public short X; public short Y; }
[StructLayout(LayoutKind.Sequential)] public struct SMALL_RECT { public short Left; public short Top; public short Right; public short Bottom; }
[StructLayout(LayoutKind.Sequential)] public struct CSBI { public COORD dwSize; public COORD dwCursorPosition; public ushort wAttributes; public SMALL_RECT srWindow; public COORD dwMaximumWindowSize; }
[DllImport("kernel32.dll", SetLastError = true)] public static extern bool GetConsoleScreenBufferInfo(IntPtr hConsoleOutput, out CSBI lpConsoleScreenBufferInfo);
'@
    # -PassThru devuelve la clase Y las structs anidadas, en un arreglo. Hay que
    # quedarse con la clase, si no la llamada cae en [Object[]] y no existe.
    Add-Type -MemberDefinition $firma -Name Consola -Namespace Dieciocho
    $k = [Dieciocho.Consola]

    [void]$k::FreeConsole()
    if (-not $k::AttachConsole([uint32]$ProcesoId)) { exit 0 }

    # GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, OPEN_EXISTING.
    # El acceso va en decimal: PowerShell lee 0xC0000000 como un Int32 negativo
    # y la conversion a UInt32 revienta.
    $acceso = [uint32]3221225472
    $h = $k::CreateFile("CONOUT$", $acceso, [uint32]3, [IntPtr]::Zero, [uint32]3, [uint32]0, [IntPtr]::Zero)
    if ($h -eq [IntPtr]::Zero -or $h -eq [IntPtr](-1)) { exit 0 }

    $info = New-Object -TypeName "Dieciocho.Consola+CSBI"
    if ($k::GetConsoleScreenBufferInfo($h, [ref]$info)) {
        $filas = $info.srWindow.Bottom - $info.srWindow.Top + 1
        if ($filas -gt 0) { [Console]::Out.Write("$filas") }
    }
} catch {
    exit 0
}
