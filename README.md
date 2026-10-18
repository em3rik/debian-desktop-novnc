### debian-desktop-novnc
Debian Slim based Docker image with a minimal XFCE session, noVNC (v1.7.0) and Chromium.

### Build the docker image
```
sudo docker build -t debian-slim-xfce-novnc-image .
```
### Run the container detached (in the background)
```
sudo docker run -d -p 6080:6080 debian-slim-xfce-novnc-image
```
### Access the desktop
https://localhost:6080

Note: **https**, not http - websockify serves TLS with a self-signed certificate
(generated at first container start), so the browser will show a one-time
warning you need to accept.

### Environment variables

| Variable | Default | Description |
|---|---|---|
| VNC_RESOLUTION | 1920x1080 | Starting desktop resolution (the browser sends real desktop-size events on resize, so this is just the initial size) |
| VNC_DEPTH | 24 | Color depth |
| VNC_PASSWORD | (unset) | If set, VNC requires password auth. If unset, the desktop is open access - set it on any non-localhost bind. |
| BROWSER | /usr/bin/chromium | Default browser used by the desktop |

Example with a password:
```
sudo docker run -d -p 6080:6080 -e VNC_PASSWORD=choose-one debian-slim-xfce-novnc-image
```

### Debugging
The desktop is served over HTTPS on 6080 (noVNC + websockify). Raw VNC
(5901) is intentionally **not** published - it has no TLS and its password
auth is trivially sniffable; if you must attach a native VNC client for
debugging, map it explicitly (`-p 127.0.0.1:5901:5901`) and tunnel it.

No `--privileged` or extra capabilities are needed - Xvnc runs fine with
Docker's default security settings.
