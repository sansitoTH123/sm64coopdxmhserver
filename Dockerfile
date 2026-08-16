# Usamos una base de Ubuntu moderna y ligera
FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias necesarias para compilar sm64coopdx y descargar archivos
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    libsdl2-dev \
    libcurl4-openssl-dev \
    libcrypto++-dev \
    libglew-dev \
    libuv1-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Clonar el código fuente oficial de sm64coopdx
WORKDIR /app
RUN git clone --recursive https://github.com .

# Compilar la versión 'headless' (servidor dedicado sin gráficos)
RUN make HEADLESS=1

# Crear la carpeta de mods e inyectar el mod de Mario Hunt automáticamente
RUN mkdir -p /root/.local/share/sm64coopdx/mods
RUN curl -L -o /root/.local/share/sm64coopdx/mods/mario_hunt.pcode https://github.com || true

# Exponer el puerto requerido por Render
EXPOSE 8080

# Comando para ejecutar el servidor conectado a CoopNet con Mario Hunt activado
CMD ./sm64coopdx --headless --coopnet "" --playername "Servidor Mario Hunt 24/7" --playercount 16 --console --port 8080
