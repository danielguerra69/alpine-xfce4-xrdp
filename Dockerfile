FROM danielguerra/alpine-sshdx


ADD apk /tmp/apk
RUN cp /tmp/apk/.abuild/-57cfc5fa.rsa.pub /etc/apk/keys

RUN apk --update --no-cache add xrdp xvfb alpine-desktop xfce4 thunar-volman \
faenza-icon-theme slim xf86-input-synaptics xf86-input-mouse xf86-input-keyboard \
setxkbmap sudo util-linux dbus ttf-freefont xauth supervisor \
&& apk add /tmp/apk/ossp-uuid-1.6.2-r0.apk \
&& apk add /tmp/apk/ossp-uuid-dev-1.6.2-r0.apk \
&& apk add /tmp/apk/x11vnc-0.9.13-r0.apk \
&& rm -rf /tmp/* /var/cache/apk/*

ADD etc /etc

RUN addgroup alpine \
&& adduser  -G alpine -s /bin/sh -D alpine \
&& echo "alpine:alpine" | /usr/sbin/chpasswd \
&& echo "alpine    ALL=(ALL) ALL" >> /etc/sudoers \
&& echo "exec xfce4-session" >> /home/alpine/.xinitrc \
&& echo xfce4-session >/home/alpine/.xsession \
&& chown -R alpine:alpine /home/alpine

RUN xrdp-keygen xrdp auto
RUN sed -i '/TerminalServerUsers/d' /etc/xrdp/sesman.ini \
&& sed -i '/TerminalServerAdmins/d' /etc/xrdp/sesman.ini

EXPOSE 3389 22
#WORKDIR /home/alpine
#USER alpine
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
