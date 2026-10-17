# Terminal Walkie

Terminal Walkie busca conectar estas etapas:

```text
push-to-talk -> STT local -> SSH/Tailscale -> TTS remoto
```

Las dos primitivas conceptuales del proyecto son:

```sh
hablar "<texto>"
transmitir
```

`hablar` pronuncia texto en la maquina que ejecuta el comando. La primera
version portable para Linux usa eSpeak en espanol. `transmitir` todavia no
esta implementado; tampoco hay STT ni hotkeys en esta etapa.

## Linux

Consulta [linux/hablar/README.md](linux/hablar/README.md) para dependencias,
instalacion y uso de `hablar`.

## Estado

La base compartida y el soporte inicial de Linux estan en desarrollo.
Windows se documentara por separado en [docs/windows.md](docs/windows.md).
