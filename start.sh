#!/bin/bash

# -----
# Start order: Xvnc -> XFCE -> noVNC (foreground, keeps container alive)
# -----

export DISPLAY=:1

# Cleanup any leftover X lock on display :1
rm -f /tmp/.X11-unix/X1

# Signal handling - graceful shutdown on docker stop
cleanup() {
    echo "[start.sh] Shutting down..."
    pkill -TERM xfce4-session 2>/dev/null || true
    sleep 0.5
    pkill -TERM Xvnc 2>/dev/null || true
    sleep 0.5
    pkill -9 -f Xvnc 2>/dev/null || true
    pkill -9 -f xfce4 2>/dev/null || true
    echo "[start.sh] Exit."
    exit 0
}
trap cleanup SIGTERM SIGINT

# --- 1. Start Xvnc (TigerVNC) with dynamic resize support ---
VNC_GEOMETRY="${VNC_RESOLUTION:-1920x1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"

echo "[start.sh] Starting Xvnc on ${VNC_GEOMETRY} ..."
Xvnc :1 \
    -geometry "${VNC_GEOMETRY}" \
    -depth "${VNC_DEPTH}" \
    -SecurityTypes None \
    -auth /root/.Xauthority \
    -listen tcp \
    -rfbport 5901 \
    -AcceptSetDesktopSize &
XVNC_PID=$!
disown $XVNC_PID

# Wait for Xvnc to bind (up to 15 seconds)
echo "[start.sh] Waiting for Xvnc to be ready..."
for i in $(seq 1 30); do
    if lsof -i :5901 >/dev/null 2>&1; then
        echo "[start.sh] Xvnc ready (port 5901)."
        break
    fi
    if ! kill -0 $XVNC_PID 2>/dev/null; then
        echo "[start.sh] ERROR: Xvnc died during startup."
        exit 1
    fi
    sleep 0.5
done

# --- 2. Start XFCE desktop ---
echo "[start.sh] Starting XFCE4 ..."
startxfce4 &
disown

# Give XFCE a moment to initialize before noVNC starts
sleep 2

# --- 3. Start noVNC via websockify (foreground - keeps container alive) ---
# noVNC v1.5.0 no longer has launch.sh. Use websockify directly:
#   websockify.py --web <noVNC dir> <listen_port> <vnc_host:port>
echo "[start.sh] Starting noVNC on port 6080 ..."
export PYTHONPATH=/usr/share/novnc/utils/websockify
exec python3 -m websockify \
    --web /usr/share/novnc \
    6080 localhost:5901
