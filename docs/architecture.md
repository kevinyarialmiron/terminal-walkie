# Architecture

Terminal Walkie is organized around a small voice-message path:

```text
push-to-talk -> local STT -> SSH/Tailscale -> remote TTS
```

Only the remote TTS primitive is represented today, through `hablar`. The
Linux implementation uses eSpeak as its initial backend because that is the
currently proven local behavior.

`transmitir` will eventually coordinate capture, STT, transport, and remote
speech. It is intentionally not implemented yet. Hotkeys and STT are also out
of scope for this phase.
