ARG BASE_IMAGE="ubuntu:22.04"
ARG EASY_NOVNC_IMAGE="fhriley/easy-novnc:1.3.0"
ARG TURBOVNC_IMAGE="fhriley/turbovnc:2.2.7"

FROM $EASY_NOVNC_IMAGE as easy-novnc
FROM $TURBOVNC_IMAGE as turbovnc
FROM $BASE_IMAGE as build

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        build-essential \
        git \
        libcurl4-gnutls-dev \
        libmediainfo-dev \
        qt5-qmake \
        qtbase5-dev \
        qtbase5-dev-tools \
        qtdeclarative5-dev \
        qtmultimedia5-dev \
        qttools5-dev \
        qttools5-dev-tools \
        libqt5opengl5 \
        libqt5opengl5-dev \
        libqt5svg5 \
        libqt5svg5-dev \
        qml-module-qtquick-controls \
        qml-module-qtqml-models2 \
        \
        cmake \
        ca-certificates \
        ninja-build \
        xfonts-base \
    && update-ca-certificates \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ARG MEDIAELCH_BRANCH=v2.8.14
RUN cd /tmp \
    && git clone --depth=1 --branch ${MEDIAELCH_BRANCH} https://github.com/Komet/MediaElch.git \
    && cd MediaElch \
    && git submodule update --init \
    && cmake -S . --preset=release -DDISABLE_UPDATER=ON \
    && cmake --build build/release -j $(nproc) \
    && cmake --install build/release \
    && cmake --install build/release/third_party/quazip


FROM $BASE_IMAGE

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        libqt5sql5 \
        libqt5sql5-sqlite \
        libqt5core5a \
        libqt5gui5 \
        libqt5network5 \
        libqt5concurrent5 \
        libqt5svg5 \
        qml-module-qtgraphicaleffects \
        qml-module-qtquick-controls \
        qml-module-qtqml-models2 \
        libqt5qml5 \
        libqt5multimedia5 \
        libqt5multimediawidgets5 \
        libqt5opengl5 \
        libqt5xml5 \
        libmediainfo0v5 \
        zlib1g \
        libzen0v5 \
        libcurl4 \
        libpulse0 \
        libqt5quickwidgets5 \
        libqt5quick5 \
       	\
       	ca-certificates \
       	curl \
       	ffmpeg \
       	gosu \
       	icewm \
        supervisor \
        xauth \
        xfonts-base \
        xkb-data \
        x11-xkb-utils \
        x11-xserver-utils \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# assets.fanart.tv uses a ZeroSSL cert
RUN curl -sfL -o /usr/local/share/ca-certificates/ZeroSSL.crt "https://crt.sh/?d=2427368505" \
    && update-ca-certificates

ARG MEDIAELCH_BRANCH=v2.8.14
RUN mkdir -p /usr/local/share/MediaElch \
    && curl -sfL -o /usr/local/share/MediaElch/advancedsettings.xml \
       https://raw.githubusercontent.com/Komet/MediaElch/${MEDIAELCH_BRANCH}/docs/advancedsettings.xml

COPY supervisord.conf /etc/
COPY docker-entrypoint.sh /
COPY icewm /etc/X11/icewm

COPY --from=easy-novnc /usr/local/bin/easy-novnc /usr/local/bin/easy-novnc
COPY --from=turbovnc /opt/TurboVNC /opt/TurboVNC
COPY --from=build /usr/local/bin/MediaElch /usr/local/bin/MediaElch
COPY --from=build /usr/local/share/applications/MediaElch.desktop /usr/local/share/applications/MediaElch.desktop
COPY --from=build /usr/local/share/pixmaps/MediaElch.png /usr/local/share/pixmaps/MediaElch.png
COPY --from=build /usr/local/share/metainfo/com.kvibes.MediaElch.metainfo.xml /usr/local/share/metainfo/com.kvibes.MediaElch.metainfo.xml
COPY --from=build /usr/local/lib/libquazip1-qt5.so* /usr/local/lib/

CMD ["/docker-entrypoint.sh"]

VOLUME /data
VOLUME /media/movies
VOLUME /media/tv

# HTTP (noVNC) 
EXPOSE 8000/tcp

# VNC
EXPOSE 5900/tcp

ENV MEDIAELCH_UID=2000
ENV MEDIAELCH_GID=2000

#ENV QT_DEBUG_PLUGINS=1

