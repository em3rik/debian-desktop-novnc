### debian-desktop-novnc
Debian based Docker image with noVNC and essential tools installed

### Build the docker image
```
sudo docker build -t debian-slim-xfce-novnc-image .
```
### Run the container detached (in the background)
```
sudo docker run -d -p 6080:6080 debian-slim-xfce-novnc-image
```
### Access running container
http://localhost:6080

##### Run the container in the debug mode
```
sudo docker run --cap-add=SYS_ADMIN --device=/dev/tty0 --privileged -p 6080:6080 -p 5901:5901 debian-slim-xfce-novnc-image
```
