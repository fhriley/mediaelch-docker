ARG BASE_IMAGE="ubuntu:22.04"

FROM golang:1.17-buster AS easy-novnc-build

ARG EASY_NOVNC_BRANCH=v1.3.0
RUN cd $GOPATH/src \
  && git clone --depth=1 --branch ${EASY_NOVNC_BRANCH} https://github.com/fhriley/easy-novnc \
  && cd $GOPATH/src/easy-novnc \
  && go mod download \
  && go build -o /bin/easy-novnc


FROM $BASE_IMAGE as build

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        build-essential \
        curl \
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
        libpam0g-dev \
        ninja-build \
        xfonts-base \
        yasm \
    && update-ca-certificates \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ARG TURBOJPEG_BRANCH=2.1.2
RUN cd /tmp \
    && git clone --depth=1 --branch ${TURBOJPEG_BRANCH} https://github.com/libjpeg-turbo/libjpeg-turbo.git \
    && cd libjpeg-turbo \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make -j $(nproc) \
    && make install

ARG TURBOVNC_BRANCH=2.2.7
RUN cd /tmp \
    && git clone --depth=1 --branch ${TURBOVNC_BRANCH} https://github.com/TurboVNC/turbovnc.git \
    && cd turbovnc \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DTVNC_USETLS=0 -DTVNC_BUILDVIEWER=0 -DTVNC_BUILDSERVER=1 -DTVNC_BUILDJAVA=0 -DTVNC_BUILDWEBSERVER=0 .. \
    && make -j $(nproc) \
    && make install

ARG MEDIAELCH_BRANCH=v2.8.14
RUN cd /tmp \
    && git clone --depth=1 --branch ${MEDIAELCH_BRANCH} https://github.com/Komet/MediaElch.git \
    && cd MediaElch \
    && git submodule update --init \
    && cmake -S . --preset=release \
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
        tigervnc-standalone-server \
        xfonts-base \
        x11-xserver-utils \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ARG MEDIAELCH_BRANCH=v2.8.14

# assets.fanart.tv uses a ZeroSSL cert
RUN curl -sfL -o /usr/local/share/ca-certificates/ZeroSSL.crt "https://crt.sh/?d=2427368505" \
    && update-ca-certificates \
    && mkdir -p /usr/local/share/MediaElch \
    && curl -sfL -o /usr/local/share/MediaElch/advancedsettings.xml \
       https://raw.githubusercontent.com/Komet/MediaElch/${MEDIAELCH_BRANCH}/docs/advancedsettings.xml


COPY supervisord.conf /etc/
COPY docker-entrypoint.sh /
COPY xstartup /usr/local/share/xstartup
COPY icewm /etc/X11/icewm

COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/
COPY --from=build /opt/TurboVNC /opt/TurboVNC
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

