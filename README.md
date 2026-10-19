### debian-desktop-novnc
Debian Slim based Docker image with a minimal XFCE session, noVNC (v1.7.0), Firefox ESR and Chromium.

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
| BROWSER | /usr/bin/firefox-esr | Default browser used by the desktop (chromium also installed) |

Example with a password:
```
sudo docker run -d -p 6080:6080 -e VNC_PASSWORD=choose-one debian-slim-xfce-novnc-image
```

### Fonts
Default UI font is **Nimbus Sans 10** - URW's Helvetica-metric clone
(`fonts-urw-base35`), set as an xfconf system-wide default
(`/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml`), so a fresh home
picks it up and a user override via *Settings > Appearance* still wins.

Because the image uses `--no-install-recommends`, font packages must be
listed explicitly in the Dockerfile. `fonts-dejavu-core` is load-bearing:
without it, fontconfig resolves the generic `Sans`/`sans-serif` to
Liberation **Mono** and the entire desktop renders monospaced.
Installed: `fonts-urw-base35` (Nimbus Sans/Ra/Pa...), `fonts-dejavu-core`
(generic sans/mono), `fonts-liberation` (Arial/Times/Courier metrics for
documents), `xfonts-base` (X11 core bitmaps).

### Network tools
`ping`, `host`, `dig`, `nslookup` are installed (`iputils-ping`,
`bind9-dnsutils`) - both were Recommends-only casualties of
`--no-install-recommends` and are needed for in-desktop debugging.

### Debugging
The desktop is served over HTTPS on 6080 (noVNC + websockify). Raw VNC
(5901) is intentionally **not** published - it has no TLS and its password
auth is trivially sniffable; if you must attach a native VNC client for
debugging, map it explicitly (`-p 127.0.0.1:5901:5901`) and tunnel it.

No `--privileged` or extra capabilities are needed - Xvnc runs fine with
Docker's default security settings.
