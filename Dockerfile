FROM danielguerra/alpine-sdk:edge as builder
MAINTAINER Daniel Guerra

RUN abuild-keygen -a -n
#RUN sed -i 's/pkgver=0\.9\.13/pkgver=0\.9\.10/' APKBUILD
#RUN abuild checksum
WORKDIR /tmp/aports
RUN git pull
WORKDIR /tmp/aports/community/xrdp
RUN abuild fetch
RUN abuild unpack
RUN abuild deps
RUN abuild prepare
RUN abuild build
RUN abuild rootpkg

WORKDIR /tmp/aports/community/pulseaudio
RUN abuild fetch
RUN abuild unpack
RUN abuild deps
RUN abuild prepare
RUN abuild build
RUN abuild rootpkg
WORKDIR /tmp/aports/community/pulseaudio/src/pulseaudio-13.0
RUN cp ./output/config.h .

WORKDIR /tmp/aports/community/xorgxrdp
RUN abuild fetch
RUN abuild unpack
RUN abuild deps
RUN abuild prepare
RUN abuild build
RUN abuild rootpkg

ARG XRDPPULSE_VER="0.4"
ENV XRDPPULSE_VER=${XRDPPULSE_VER}
RUN echo sdk | sudo -S apk update
RUN echo sdk | sudo -S apk add pulseaudio-dev xrdp-dev xorgxrdp-dev
WORKDIR /tmp
RUN wget https://github.com/neutrinolabs/pulseaudio-module-xrdp/archive/v"${XRDPPULSE_VER}".tar.gz -O pulseaudio-module-xrdp-"${XRDPPULSE_VER}".tar.gz
RUN tar -zxf pulseaudio-module-xrdp-"${XRDPPULSE_VER}".tar.gz
WORKDIR /tmp/pulseaudio-module-xrdp-"${XRDPPULSE_VER}"
RUN ./bootstrap
RUN ./configure PULSE_DIR=/tmp/aports/community/pulseaudio/src/pulseaudio-13.0
RUN make
RUN echo sdk | sudo -S make install

RUN ls -al /tmp/pulseaudio-module-xrdp-0.4/src/.libs/module-xrdp-sink.so
RUN ls -al  /tmp/pulseaudio-module-xrdp-0.4/src/.libs/module-xrdp-source.so

# RUN STOP

FROM alpine:edge
MAINTAINER Daniel Guerra

RUN apk --update --no-cache add \
    alpine-conf \
    bash \
    chromium \
    dbus \
    faenza-icon-theme \
    firejail \
    libpulse \
    openssh \
    paper-gtk-theme \
    paper-icon-theme \
    pavucontrol \
    pulseaudio \
    pulseaudio-utils \
    pulsemixer \
    setxkbmap \
    slim \
    sudo \
    supervisor \
    thunar-volman \
    ttf-freefont \
    util-linux \
    vim \
    vlc-qt \
    xauth \
    xf86-input-keyboard \
    xf86-input-mouse \
    xf86-input-synaptics \
    xfce4 \
    xfce4-pulseaudio-plugin \
    xfce4-terminal \
    xinit \
    xorg-server \
    xorgxrdp \
    xrdp \
&& rm -rf /tmp/* /var/cache/apk/*

# RUN rm -rf /usr/lib/pulse-13.0/modules
COPY --from=builder /usr/lib/pulse-13.0/modules /usr/lib/pulse-13.0/modules
COPY --from=builder  /tmp/pulseaudio-module-xrdp-0.4/src/.libs  /tmp/libs
WORKDIR /tmp/libs
COPY --from=builder  /tmp/pulseaudio-module-xrdp-0.4/build-aux/install-sh /bin
RUN install-sh -c -d '/usr/lib/pulse-13.0/modules'

#COPY --from=builder /home/sdk/packages/testing/x86_64/firefox.apk /tmp/firefox.apk
RUN ldconfig -n /usr/lib/pulse-13.0/modules
RUN ls $(pkg-config --variable=modlibexecdir libpulse)

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
