# `hablar` para Windows

Este directorio contiene una implementación portable del comando `hablar`.

## Dependencias

- Windows PowerShell 5.1 o posterior.
- Python 3.10 o posterior, disponible como `py -3` o `python`.
- Conectividad a Internet para que `edge-tts` pueda generar el audio.
- Una sesión gráfica de Windows para que `MediaPlayer` pueda reproducirlo por los parlantes.

`install.ps1` instala `edge-tts` en el entorno de usuario mediante pip. No crea ni incluye un venv, no vendoriza paquetes y no requiere credenciales.

## Instalación

Desde PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

La instalación:

1. verifica que Python esté disponible;
2. instala la versión fijada de `edge-tts` desde `requirements.txt` en el entorno de usuario;
3. crea o actualiza un acceso directo en la carpeta Startup del usuario para iniciar el agente al entrar a Windows.

Para no crear el acceso directo de inicio automático:

```powershell
.\install.ps1 -SkipStartup
```

La instalación no desinstala ni reemplaza una instalación existente y tampoco modifica `C:\Tools\hablar`.

## Por qué existe el agente gráfico

`hablar` puede ejecutarse desde una consola SSH, pero una sesión SSH sola normalmente no tiene acceso al escritorio ni al dispositivo de audio de la sesión interactiva. El agente se inicia dentro de la sesión gráfica, recibe solicitudes por un named pipe, genera audio con Edge TTS y lo reproduce con `MediaPlayer`.

El agente no guarda logs. El MP3 se crea en la carpeta temporal del usuario solamente durante la reproducción y se elimina al terminar.

## Uso

Con el agente activo en la sesión gráfica:

```text
hablar "texto a reproducir"
```

También se puede invocar directamente desde PowerShell:

```powershell
.\hablar.cmd "texto a reproducir"
```

El cliente envía JSON UTF-8 por el named pipe y espera una respuesta antes de terminar. El nombre del pipe y la voz son configurables:

```powershell
$env:HABLAR_PIPE_NAME = 'hablar-audio-v1'
$env:HABLAR_VOICE = 'es-AR-ElenaNeural'
```

Variables soportadas:

- `HABLAR_PIPE_NAME`: nombre del named pipe, por defecto `hablar-audio-v1`.
- `HABLAR_VOICE`: voz de Edge TTS, por defecto `es-AR-ElenaNeural`.
- `HABLAR_PYTHON`: ruta opcional al ejecutable Python.
- `HABLAR_CONNECT_TIMEOUT_MS`: timeout del cliente, por defecto `3000`.

El agente y el cliente deben usar el mismo nombre de pipe. Las variables configuradas como variables de entorno de usuario son una forma portable de persistir estos parámetros.

## Alcance de esta fase

Esta versión implementa únicamente `hablar` y su agente de audio. No incluye `transmitir`, Handy, hotkeys, STT, claves SSH ni modelos STT.
