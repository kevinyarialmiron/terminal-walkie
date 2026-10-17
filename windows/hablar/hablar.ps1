[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $Texto
)

$ErrorActionPreference = 'Stop'
$pipeName = if ($env:HABLAR_PIPE_NAME) { $env:HABLAR_PIPE_NAME } else { 'hablar-audio-v1' }
$timeoutMs = 3000
if ($env:HABLAR_CONNECT_TIMEOUT_MS) {
    $parsedTimeout = 0
    if ([int]::TryParse($env:HABLAR_CONNECT_TIMEOUT_MS, [ref]$parsedTimeout) -and $parsedTimeout -gt 0) {
        $timeoutMs = $parsedTimeout
    }
}

if (-not $Texto -or $Texto.Count -eq 0) {
    throw 'Uso: hablar "texto a reproducir"'
}

$frase = ($Texto -join ' ')
$pipe = $null
$writer = $null
$reader = $null
try {
    $pipe = [System.IO.Pipes.NamedPipeClientStream]::new('.', $pipeName, [System.IO.Pipes.PipeDirection]::InOut, [System.IO.Pipes.PipeOptions]::None)
    $pipe.Connect($timeoutMs)
    $pipe.ReadMode = [System.IO.Pipes.PipeTransmissionMode]::Byte

    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $writer = [System.IO.StreamWriter]::new($pipe, $utf8, 4096, $true)
    $reader = [System.IO.StreamReader]::new($pipe, $utf8, $false, 4096, $true)
    $writer.AutoFlush = $true
    $writer.WriteLine((@{ Text = $frase } | ConvertTo-Json -Compress))
    $responseLine = $reader.ReadLine()
    if (-not $responseLine) { throw 'El agente de audio cerró la conexión sin responder.' }
    $response = $responseLine | ConvertFrom-Json
    if (-not $response.Ok) { throw [string]$response.Error }
}
catch [System.TimeoutException] {
    throw 'No hay un agente de audio activo en la sesión gráfica. Inicia sesión localmente y vuelve a intentarlo.'
}
finally {
    if ($reader) { $reader.Dispose() }
    if ($writer) { $writer.Dispose() }
    if ($pipe) { $pipe.Dispose() }
}
