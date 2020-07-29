# About

Alpine linux xrdp server with xfce4 rdp server with vlc and chromium.
The xrdp audio is working and everything runs unprivileged.
Sessions run in firejail for security. Chromium sandbox is disabled.



# Start the server

```bash
docker run -d --name rdp --shm-size 1g -p 3389:3389 danielguerra/alpine-xfce4-xrdp
```

(WARNING: use the --shm-size 1g or chromium will crash)

# Connect with your favorite rdp client

User: alpine
Pass: alpine

# Change the alpine user password

```bash
docker exec -ti rdp passwd alpine
```

# Add users

```bash
docker exec -ti rdp adduser myuser
```
