[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$pipeName = if ($env:HABLAR_PIPE_NAME) { $env:HABLAR_PIPE_NAME } else { 'hablar-audio-v1' }
$voice = if ($env:HABLAR_VOICE) { $env:HABLAR_VOICE } else { 'es-AR-ElenaNeural' }
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ttsScript = Join-Path $scriptRoot 'tts_generate.py'

function Resolve-Python {
    if ($env:HABLAR_PYTHON) {
        if (-not (Test-Path -LiteralPath $env:HABLAR_PYTHON)) { throw "No existe HABLAR_PYTHON: $env:HABLAR_PYTHON" }
        return @{ Executable = $env:HABLAR_PYTHON; Prefix = @() }
    }
    $py = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($py) { return @{ Executable = $py.Source; Prefix = @('-3') } }
    $python = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($python) { return @{ Executable = $python.Source; Prefix = @() } }
    throw 'No se encontró Python. Instala Python 3.10 o posterior o configura HABLAR_PYTHON.'
}

function Quote-ProcessArgument([string]$value) {
    return '"' + ($value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-Tts([string]$text, [string]$mediaPath) {
    $python = Resolve-Python
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $python.Executable
    $arguments = @($python.Prefix | ForEach-Object { Quote-ProcessArgument $_ })
    $arguments += (Quote-ProcessArgument '-u')
    $arguments += (Quote-ProcessArgument $ttsScript)
    $psi.Arguments = $arguments -join ' '
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables['HABLAR_TEXT_B64'] = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
    $psi.EnvironmentVariables['HABLAR_OUTPUT'] = $mediaPath
    $psi.EnvironmentVariables['HABLAR_VOICE'] = $voice
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi
    if (-not $process.Start()) { throw 'No se pudo iniciar edge-tts.' }
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $mediaPath)) {
        throw "edge-tts falló ($($process.ExitCode)): $stderr"
    }
}

function Play-Media([string]$mediaPath) {
    $player = [System.Windows.Media.MediaPlayer]::new()
    try {
        $player.Open([Uri]$mediaPath)
        $deadline = (Get-Date).AddSeconds(15)
        while (-not $player.NaturalDuration.HasTimeSpan -and (Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 50
        }
        if (-not $player.NaturalDuration.HasTimeSpan) { throw 'El reproductor no pudo abrir el audio.' }
        $player.Play()
        Start-Sleep -Milliseconds ([Math]::Max(200, [int]$player.NaturalDuration.TimeSpan.TotalMilliseconds + 250))
    }
    finally { if ($player) { $player.Close() } }
}

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

while ($true) {
    $server = $null
    $reader = $null
    $writer = $null
    $media = $null
    try {
        $server = [System.IO.Pipes.NamedPipeServerStream]::new($pipeName, [System.IO.Pipes.PipeDirection]::InOut, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::None)
        $server.WaitForConnection()
        $utf8 = [System.Text.UTF8Encoding]::new($false)
        $reader = [System.IO.StreamReader]::new($server, $utf8, $false, 4096, $true)
        $writer = [System.IO.StreamWriter]::new($server, $utf8, 4096, $true)
        $writer.AutoFlush = $true
        $line = $reader.ReadLine()
        if (-not $line) { continue }
        $request = $line | ConvertFrom-Json
        $text = [string]$request.Text
        if ([string]::IsNullOrWhiteSpace($text)) { throw 'Texto vacío.' }
        $media = Join-Path ([System.IO.Path]::GetTempPath()) ("hablar-{0}.mp3" -f [guid]::NewGuid())
        Invoke-Tts $text $media
        Play-Media $media
        $writer.WriteLine((@{ Ok = $true } | ConvertTo-Json -Compress))
    }
    catch {
        try { if ($writer) { $writer.WriteLine((@{ Ok = $false; Error = $_.Exception.Message } | ConvertTo-Json -Compress)) } } catch {}
    }
    finally {
        if ($media -and (Test-Path -LiteralPath $media)) { Remove-Item -LiteralPath $media -Force -ErrorAction SilentlyContinue }
        if ($reader) { $reader.Dispose() }
        if ($writer) { $writer.Dispose() }
        if ($server) { $server.Dispose() }
    }
}
