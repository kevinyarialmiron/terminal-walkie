# hablar para Linux

`hablar` pronuncia el texto recibido usando eSpeak y su voz en espanol. Es la
primera version portable del comando; no instala ni reemplaza ningun comando
en el sistema.

## Dependencia

Instala eSpeak con el gestor de paquetes de tu distribucion. Por ejemplo:

```sh
# Debian/Ubuntu
sudo apt install espeak

# Fedora
sudo dnf install espeak

# Arch Linux
sudo pacman -S espeak
```

Comprueba que `espeak` este disponible:

```sh
espeak --version
```

## Uso directo

Desde la raiz del repositorio:

```sh
./linux/hablar/hablar "Hola desde Terminal Walkie"
```

## Instalacion opcional

Para usarlo como `hablar`, copia el script a un directorio de tu `PATH`:

```sh
install -Dm755 linux/hablar/hablar "$HOME/.local/bin/hablar"
```

Esto es una accion manual del operador; el repositorio no modifica el sistema
ni reemplaza instalaciones existentes.

## Comportamiento

Sin argumentos, el comando muestra una linea de uso y sale con codigo `64`.
Con texto, ejecuta `espeak -v es` y entrega el texto como un unico argumento.
