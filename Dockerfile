FROM danielguerra/alpine-sdk:edge as builder
MAINTAINER Daniel Guerra

RUN abuild-keygen -a -n

WORKDIR /tmp/aports
RUN git pull


ARG PULSEAUDIO_VER="14.2"
ENV PULSEAUDIO_VER=${PULSEAUDIO_VER}
ARG XRDPPULSE_VER="0.5"
ENV XRDPPULSE_VER=${XRDPPULSE_VER}
RUN echo sdk | sudo -S apk --update --no-cache upgrade
RUN echo sdk | sudo -S apk --update --no-cache add doxygen
ADD pulse-patch /tmp
WORKDIR /tmp/aports/community/pulseaudio
RUN abuild fetch
RUN abuild unpack
RUN abuild deps
RUN abuild prepare
RUN patch -p1  -t /tmp/aports/community/pulseaudio/src/pulseaudio-"${PULSEAUDIO_VER}"/src/modules/meson.build < /tmp/pulse-patch
RUN abuild build
RUN abuild rootpkg
WORKDIR /tmp/aports/community/pulseaudio/src/pulseaudio-"${PULSEAUDIO_VER}"
RUN cp ./output/config.h .

RUN echo sdk | sudo -S apk update
RUN echo sdk | sudo -S apk add pulseaudio pulseaudio-dev xrdp-dev xorgxrdp-dev nasm autoconf automake musl-dev
WORKDIR /tmp
RUN wget https://github.com/neutrinolabs/pulseaudio-module-xrdp/archive/v"${XRDPPULSE_VER}".tar.gz -O pulseaudio-module-xrdp-"${XRDPPULSE_VER}".tar.gz
RUN tar -zxf pulseaudio-module-xrdp-"${XRDPPULSE_VER}".tar.gz
WORKDIR /tmp/pulseaudio-module-xrdp-"${XRDPPULSE_VER}"
RUN ./bootstrap
RUN ./configure PULSE_DIR=/tmp/aports/community/pulseaudio/src/pulseaudio-"${PULSEAUDIO_VER}"
RUN echo sdk | sudo -S make
RUN echo sdk | sudo -S make install

RUN ls -al /tmp/pulseaudio-module-xrdp-"${XRDPPULSE_VER}"/src/.libs/module-xrdp-sink.so
RUN ls -al  /tmp/pulseaudio-module-xrdp-"${XRDPPULSE_VER}"/src/.libs/module-xrdp-source.so

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
COPY --from=builder /usr/lib/pulse-"${PULSEAUDIO_VER}"/modules /usr/lib/pulse-"${PULSEAUDIO_VER}"/modules
COPY --from=builder  /tmp/pulseaudio-module-xrdp-"${XRDPPULSE_VER}"/src/.libs  /tmp/libs
WORKDIR /tmp/libs
COPY --from=builder  /tmp/pulseaudio-module-xrdp-"${XRDPPULSE_VER}"/build-aux/install-sh /bin
RUN install-sh -c -d '/usr/lib/pulse-"${PULSEAUDIO_VER}"/modules'

#COPY --from=builder /home/sdk/packages/testing/x86_64/firefox.apk /tmp/firefox.apk
RUN ldconfig -n /usr/lib/pulse-"${PULSEAUDIO_VER}"/modules
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
