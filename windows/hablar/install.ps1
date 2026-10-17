[CmdletBinding()]
param(
    [switch] $SkipStartup
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$requirements = Join-Path $scriptRoot 'requirements.txt'

$pythonCommand = Get-Command py.exe -ErrorAction SilentlyContinue
if ($pythonCommand) {
    & $pythonCommand.Source -3 -m pip install --user --requirement $requirements
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo instalar edge-tts con py -3.' }
} else {
    $pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
    if (-not $pythonCommand) { throw 'No se encontró Python. Instala Python 3.10 o posterior.' }
    & $pythonCommand.Source -m pip install --user --requirement $requirements
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo instalar edge-tts con python.' }
}

if (-not $SkipStartup) {
    $startup = [Environment]::GetFolderPath('Startup')
    $shortcutPath = Join-Path $startup 'Terminal Walkie Hablar Agent.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $shortcut.Arguments = '-NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File ' + ('"' + (Join-Path $scriptRoot 'hablar-agent.ps1') + '"')
    $shortcut.WorkingDirectory = $scriptRoot
    $shortcut.WindowStyle = 7
    $shortcut.Description = 'Agente de audio del terminal walkie'
    $shortcut.Save()
    Write-Host "Agente configurado para iniciar con la sesión gráfica: $shortcutPath"
}

Write-Host 'Instalación completada.'
