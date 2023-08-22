FROM debian:stable-slim

# Install xfce desktop environment, necessary tools, Xorg, dbus, Firefox, Chromium, and Epiphany
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-terminal curl wget xvfb \
    procps net-tools tigervnc-standalone-server \
    dbus-x11 python3-numpy xorg xserver-xorg-video-dummy dbus \
    firefox-esr chromium dillo lynx \
    htop && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set BROWSER environment variable to default to Firefox
ENV BROWSER=/usr/bin/firefox-esr

# Set VNC_NO_PASSWORD environment variable
ENV VNC_NO_PASSWORD=1

# Create the novnc directory
RUN mkdir -p /usr/share/novnc && \
    mkdir -p /usr/share/novnc/utils && \
    mkdir -p /usr/share/novnc/utils/websockify

# Install noVNC
RUN curl -Ls https://github.com/novnc/noVNC/archive/v1.2.0.tar.gz | tar xz --strip 1 -C /usr/share/novnc && \
    curl -Ls https://github.com/novnc/websockify/archive/v0.10.0.tar.gz | tar xz --strip 1 -C /usr/share/novnc/utils/websockify && \
    ln -s /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html

# Generate SSL certificate
RUN cd /usr/share/novnc/utils/ && openssl req -x509 -nodes -newkey rsa:2048 -keyout self.pem -out self.pem -days 365 -subj "/C=EU/ST=Croatia/L=Zagreb/O=IDKFA/CN=nutra.strpaj.ga"

# Create the necessary directories and device files
RUN mkdir -p /tmp/.X11-unix && \
    mknod -m 666 /dev/tty1 c 4 1 && \
    ln -sf /dev/tty1 /dev/tty0

# Create an empty .Xauthority file
RUN touch /root/.Xauthority

# Copy Xdummy config file
COPY xorg.conf /etc/X11/xorg.conf

# # Set a default VNC password
# RUN apt-get update && apt-get install -y x11vnc && \
#     mkdir -p /root/.vnc && \
#     x11vnc -storepasswd yourpassword /root/.vnc/passwd && \
#     apt-get purge -y x11vnc && apt-get autoremove -y && apt-get clean

# Set up the entrypoint script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose the necessary ports
EXPOSE 6080
EXPOSE 5901

# Start the entrypoint script
CMD ["/start.sh"]
