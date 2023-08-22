#!/bin/bash

# Kill any running Xorg process (if you decide to use Xorg with Xdummy in future)
pkill -9 Xorg
rm -f /tmp/.X1-lock

# Increase the delay to ensure Xorg/Xvnc is fully started (adjust as needed)
sleep 10

# Set the display variable for XFCE
export DISPLAY=:1

# Start the xfce desktop environment
startxfce4 &

# Start Xvnc
# Check the options using `Xvnc -help` in the Debian version you are working with
# Xvnc :1 -geometry 1600x900 -depth 24 -auth ~/.Xauthority -listen tcp -rfbauth /root/.vnc/passwd -rfbport 5901 &
Xvnc :1 -geometry 1600x900 -depth 24 -SecurityTypes None -auth ~/.Xauthority -listen tcp -rfbport 5901 &


# Start noVNC
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080