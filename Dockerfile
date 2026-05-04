FROM debian:stable-slim

# Install xfce desktop, TigerVNC, websockify deps, and browsers
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-terminal \
    curl wget procps net-tools \
    tigervnc-standalone-server \
    dbus-x11 python3 \
    firefox-esr chromium \
    lsof htop \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Default browser override via env var
ENV BROWSER=/usr/bin/firefox-esr

# VNC starting resolution (changeable at runtime via resize=remote)
ENV VNC_RESOLUTION=1920x1080
ENV VNC_DEPTH=24

# Optional VNC password - set via docker run -e VNC_PASSWORD=yourpassword
# If unset, the container has open access (no password)
# ENV VNC_PASSWORD=yourpassword

# Install noVNC (latest stable) and websockify
RUN mkdir -p /usr/share/novnc/utils/websockify

RUN curl -Ls https://github.com/novnc/noVNC/archive/refs/tags/v1.5.0.tar.gz \
    | tar xz --strip 1 -C /usr/share/novnc && \
    curl -Ls https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz \
    | tar xz --strip 1 -C /usr/share/novnc/utils/websockify

# Generate self-signed SSL certificate (HTTPS optional via port 6081)
# CN is a wildcard for local access; override via -subj if behind a proxy
RUN cd /usr/share/novnc/utils && \
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout self.pem -out self.pem -days 365 \
        -subj "/C=US/ST=Local/L=Local/O=Desktop/CN=localhost"

# Prepare X authority file
RUN touch /root/.Xauthority

# Copy custom entrypoint and noVNC landing page
COPY start.sh /start.sh
RUN chmod +x /start.sh

COPY index.html /usr/share/novnc/index.html

# Expose noVNC (6080) and raw VNC (5901, only for debugging)
EXPOSE 6080
EXPOSE 5901

# Healthcheck - verifies noVNC web UI responds
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:6080/ || exit 1

# Run noVNC in foreground (keeps container alive)
CMD ["/start.sh"]
