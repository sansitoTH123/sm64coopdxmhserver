# Usamos una base de Ubuntu moderna y ligera
FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias necesarias y unzip para los mods comprimidos
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    unzip \
    libsdl2-dev \
    libcurl4-openssl-dev \
    libcrypto++-dev \
    libglew-dev \
    libuv1-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Descargar el codigo oficial empaquetado directo en la carpeta de trabajo
WORKDIR /app
RUN curl -L https://github.com/coop-deluxe/sm64coopdx \
    && unzip coop.zip \
    && cp -r sm64coopdx-main/* . \
    && cp -r sm64coopdx-main/.* . 2>/dev/null || true \
    && rm -rf sm64coopdx-main coop.zip

# Compilar la versión 'headless' (Servidor dedicado para Linux)
RUN make HEADLESS=1

# Crear la carpeta de mods interna del servidor
RUN mkdir -p /root/.local/share/sm64coopdx/mods

# 1. Copiar todos los archivos de la carpeta mods de GitHub al servidor
COPY mods/ /root/.local/share/sm64coopdx/mods/

# 2. Descomprimir el archivo mods.zip automáticamente si existe y borrar el zip sobrante
RUN if [ -f /root/.local/share/sm64coopdx/mods/mods.zip ]; then \
    unzip /root/.local/share/sm64coopdx/mods/mods.zip -d /root/.local/share/sm64coopdx/mods/ && \
    rm /root/.local/share/sm64coopdx/mods/mods.zip; \
    fi

# Exponer el puerto requerido por Render
EXPOSE 8080

# Comando definitivo que ejecuta el ejecutable headless real generado en la carpeta build
CMD ./build/us_pc/sm64coopdx --headless --coopnet "" --playername "sansitoTH Mario Hunt 24/7" --playercount 16 --console --port 8080

