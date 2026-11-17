FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    RESOLUTION=1366x768

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    procps \
    socat \
    libfuse2 \
    libgl1 \
    libgl1-mesa-dri \
    libegl1 \
    libnss3 \
    libasound2 \
    libxkbcommon-x11-0 \
    libxcb-cursor0 \
    python3 \
    python3-pip \
    python3-venv \
    python3-websockify \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    && ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then \
        URL="https://github.com/porcupine-md/anoa-browser/releases/download/v0.19.1/anoa-x86_64.AppImage"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        URL="https://github.com/porcupine-md/anoa-browser/releases/download/v0.19.1/anoa-aarch64.AppImage"; \
    else \
        echo "Unsupported arch: $ARCH" && exit 1; \
    fi \
    && wget -q -O /usr/local/bin/anoa.AppImage "$URL" \
    && chmod +x /usr/local/bin/anoa.AppImage \
    && ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/*

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh

EXPOSE 5900 6900 9224 9225

ENTRYPOINT ["/entry.sh"]
