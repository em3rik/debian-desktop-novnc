FROM debian:stable-slim

# Install a minimal XFCE session, TigerVNC, websockify deps, and both
# Firefox ESR (default) and Chromium.
# --no-install-recommends keeps the image small; XFCE components are listed
# explicitly instead of pulling the xfce4 meta-package recommends tree.
#
# Fonts MUST be listed explicitly: the xfce4 recommends tree used to deliver
# fonts-dejavu-core, and without it fontconfig resolves the generic
# "Sans"/"sans-serif" to Liberation MONO (verified on a pristine container),
# rendering the whole desktop monospaced. fonts-urw-base35 provides Nimbus
# Sans, URW's Helvetica-metric clone, used as the default UI font below.
#
# iputils-ping + bind9-dnsutils: ping / host / dig / nslookup were also
# Recommends-only casualties and are needed for in-desktop network debugging.
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4-session xfce4-settings xfwm4 xfdesktop4 xfce4-panel xfce4-terminal thunar \
    dbus-x11 x11-utils xfonts-base fonts-liberation fonts-dejavu-core fonts-urw-base35 \
    tigervnc-standalone-server tigervnc-tools \
    curl wget procps net-tools openssl python3 ca-certificates \
    iputils-ping bind9-dnsutils \
    firefox-esr chromium xdg-utils \
    lsof htop diodon xclip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Default UI font: Nimbus Sans (Helvetica clone) for GTK UI + xfwm4 titlebars.
# Shipped as an xfconf SYSTEM-WIDE default: xfconfd falls back to
# /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ whenever the user channel has no
# value, so a fresh home picks it up and a deliberate user override still wins.
COPY xfconf-defaults/xsettings.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml

# Default browser override via env var (chromium also installed)
ENV BROWSER=/usr/bin/firefox-esr

# VNC starting resolution (changeable at runtime via resize=remote)
ENV VNC_RESOLUTION=1920x1080
ENV VNC_DEPTH=24

# Optional VNC password - set via docker run -e VNC_PASSWORD=yourpassword
# If unset, the container has open access (no password)
# ENV VNC_PASSWORD=yourpassword

# Install noVNC (latest stable) and websockify
RUN mkdir -p /usr/share/novnc/utils/websockify

# -f is essential: without it a failed download pipes an HTML error page
# into tar and produces a confusing "gzip: unexpected end of file" build error
RUN curl -fLs --retry 3 --retry-delay 2 https://github.com/novnc/noVNC/archive/refs/tags/v1.7.0.tar.gz \
    | tar xz --strip 1 -C /usr/share/novnc && \
    curl -fLs --retry 3 --retry-delay 2 https://github.com/novnc/websockify/archive/refs/tags/v0.13.0.tar.gz \
    | tar xz --strip 1 -C /usr/share/novnc/utils/websockify

# NOTE: the websockify TLS certificate (self.pem) is generated at first start
# by start.sh, NOT baked into the image - the private key never ships in an
# image layer and there is no expiry surprise when running old images.

# Prepare X authority file
RUN touch /root/.Xauthority

# Copy custom entrypoint and noVNC landing page
COPY start.sh /start.sh
RUN chmod +x /start.sh

# index.html redirects to default noVNC UI with auto-resize + auto-connect
COPY index.html /usr/share/novnc/index.html

# Expose noVNC only. Raw VNC (5901) has no TLS - do not publish it;
# websockify connects to localhost:5901 inside the container.
EXPOSE 6080

# Healthcheck - verifies noVNC web UI responds (HTTPS with self-signed cert)
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fk https://localhost:6080/ || exit 1

# Run noVNC in foreground (keeps container alive)
CMD ["/start.sh"]
