FROM arm32v7/debian:stretch-slim AS target-qemu
WORKDIR /tmp
ARG QEMU_VER=qemu-5.0.0
RUN apt update && apt install -y --no-install-recommends build-essential python3 pkg-config autoconf automake libtool gettext \
    zlib1g-dev libglib2.0 libfdt-dev libpixman-1-dev libaio-dev libbz2-dev liblzo2-dev libcap-dev libcap-ng-dev libgtk-3-dev libseccomp-dev \
    ca-certificates wget && \
    rm -rf /var/lib/apt/cache/*
RUN wget -q https://download.qemu.org/${QEMU_VER}.tar.xz && tar xf ${QEMU_VER}.tar.xz && ln -s ${QEMU_VER} qemu
RUN cd qemu && \
    ./configure --prefix=$PWD/qemu-user-static --target-list="i386-linux-user" --static --disable-system --disable-tools --enable-linux-user && \
    make -j4 && make install
ADD pause.c pause.c
RUN gcc -fdata-sections -ffunction-sections -Wl,--gc-sections -Os -static -o pause pause.c
FROM arm32v7/debian:stretch-slim
WORKDIR /tmp
ARG SCANKEY_USR="ONEDRIVE"
RUN dpkg --add-architecture i386 && apt update
RUN apt install -y --no-install-recommends ca-certificates curl netbase \
    avahi-daemon avahi-utils dbus \
    sane:i386 sane-utils:i386 libsane-extras-common:i386 && \
    rm -rf /var/lib/apt/cache/*
RUN curl -O https://download.brother.com/welcome/dlf103892/brscan4-0.4.8-1.i386.deb && \
    dpkg -i brscan4-0.4.8-1.i386.deb
RUN curl -O https://download.brother.com/welcome/dlf103879/brscan-skey-0.2.4-1.i386.deb && \
    dpkg -i brscan-skey-0.2.4-1.i386.deb
COPY brscan-skey.cfg /opt/brother/scanner/brscan-skey/brscan-skey-0.2.4-0.cfg
RUN echo "user=$SCANKEY_USR" >> /opt/brother/scanner/brscan-skey/brscan-skey-0.2.4-0.cfg
COPY --from=target-qemu /tmp/qemu/qemu-user-static/bin/qemu-i386 /usr/bin/qemu-i386-static
COPY --from=target-qemu /tmp/pause /app/pause
RUN mkdir -p /var/run/dbus
COPY entrypoint.sh /app/entrypoint.sh
COPY brscan-skey_scripts/. /app/brscan-skey_scripts/
ENTRYPOINT [ "/app/entrypoint.sh" ]
CMD [ "start" ]