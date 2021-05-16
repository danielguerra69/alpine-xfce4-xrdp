FROM alpine:edge
MAINTAINER Daniel Guerra

RUN apk --update --no-cache upgrade
RUN apk --update --no-cache add \
    alpine-conf \
    bash \
    chromium \
    dbus \
    faenza-icon-theme \
    libpulse \
    openssh \
    paper-gtk-theme \
    paper-icon-theme \
    pavucontrol \
    python3 \
    py3-pip \
    setxkbmap \
    slim \
    sudo \
    thunar-volman \
    ttf-freefont \
    util-linux \
    vim \
    xauth \
    xf86-input-synaptics \
    xfce4 \
    xfce4-terminal \
    xinit \
    xorg-server \
    xorgxrdp \
    xrdp \
&& rm -rf /tmp/* /var/cache/apk/*

RUN pip3 install supervisor

RUN mkdir -p /var/log/supervisor
# add scripts/config
ADD etc /etc
ADD bin /bin

# prepare user alpine
RUN addgroup alpine \
&& adduser  -G alpine -s /bin/sh -D alpine \
&& echo "alpine:alpine" | /usr/sbin/chpasswd \
&& echo "alpine    ALL=(ALL) ALL" >> /etc/sudoers

# prepare xrdp key
RUN xrdp-keygen xrdp auto

EXPOSE 3389 22
VOLUME ["/etc/ssh"]
ENTRYPOINT ["/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]
