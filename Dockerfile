FROM alpine:3.8

# add packages
#RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk --update --no-cache add xrdp xvfb alpine-desktop xfce4 thunar-volman \
faenza-icon-theme paper-gtk-theme paper-icon-theme slim xf86-input-synaptics xf86-input-mouse xf86-input-keyboard \
setxkbmap openssh util-linux dbus wireshark ttf-freefont xauth supervisor x11vnc \
util-linux dbus ttf-freefont xauth xf86-input-keyboard sudo \
&& rm -rf /tmp/* /var/cache/apk/*

# add scripts/config
ADD etc /etc
ADD docker-entrypoint.sh /bin

# prepare user alpine
RUN addgroup alpine \
&& adduser  -G alpine -s /bin/sh -D alpine \
&& echo "alpine:alpine" | /usr/sbin/chpasswd \
&& echo "alpine    ALL=(ALL) ALL" >> /etc/sudoers
ADD alpine /home/alpine
RUN chown -R alpine:alpine /home/alpine

# prepare xrdp key
RUN xrdp-keygen xrdp auto

EXPOSE 3389 22
VOLUME ["/etc/ssh"]
ENTRYPOINT ["/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
