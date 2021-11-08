FROM ubuntu:focal as builder

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DEBIAN_FRONTEND=noninteractive
LABEL build_version="transmission version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="liofee"

COPY root/ /s6-config
# install packages
RUN \
 echo "**** install packages ****" && \
 apt update && \
 apt install -qqy \
	apt-utils \
	build-essential \
	curl \
	intltool  \
	libcurl4-openssl-dev \
	libevent-dev \
	libminiupnpc-dev \
	libssl-dev \
	libtool \
	pkg-config \
	unzip \
	zlib1g-dev && \
 mkdir /transmission-build && \
 cd /transmission-build && \
 
 echo "**** download transmission ****" && \
 curl -O https://github.com/transmission/transmission/archive/refs/tags/2.94.tar.gz && \
 tar Jxf 2.94.tar.gz && \
 cd 2.94 && \
 
 echo "**** download patch ****" && \
 mkdir patches && \
 curl https://github.com/liofee/docker-transmission/raw/master/patches/0001-path-random_announce.patch \
	-o patches/0001-path-random_announce.patch && \
 curl https://github.com/liofee/docker-transmission/raw/master/patches/0002-path-fdlimit.patch \
	-o patches/0002-path-fdlimit.patch && \
 curl https://github.com/liofee/docker-transmission/raw/master/patches/0003-path-fast_hash_check.patch \
	-o patches/0003-path-fast_hash_check.patch && \
 
 echo "**** apply patch ****" && \
 patch -N -p0 < patches/0001-path-random_announce.patch && \
 patch -N -p0 < patches/0002-path-fdlimit.patch && \
 patch -N -p0 < patches/0003-path-fast_hash_check.patch && \
 
 echo "**** setup artifact folder ****" && \
 mkdir build && \
 cd build && \
 
 echo "**** compile checks ****" && \
 ../autogen.sh --enable-daemon --disable-nls && \
 echo "**** compile start ****" && \
 make -j$(nproc) && \
 echo "**** compile finish ****" && \
 make install && \
   
 echo "**** setup default web interface  + transmission-web-control ****" && \
 cp -rp /usr/local/share/transmission/web /web && \
 cd / && \
 curl -O https://codeload.github.com/ronggang/transmission-web-control/zip/master && \
 unzip -q master && \
 rm master && \
 mv /transmission-web-control-master/src/ /transmission-web-control/ && \
 rm -rf /transmission-web-control-master/ && \
 cd / && \

 echo "**** cleanup ****" && \
 apt clean && \
 rm -rf /transmission-build && \
 echo "**** finish ****"

FROM lsiobase/ubuntu:focal

RUN \
 echo "**** install packages ****" && \
 apt update && \
 apt install -qqy \
	libcurl4 \
	libevent-2.1-7 \
	libminiupnpc17 \
	libnatpmp1 && \
 echo "**** cleanup ****" && \
 apt clean

# copy local files
COPY --from=builder /usr/local/bin/ /usr/bin/
COPY --from=builder /web  /web
COPY --from=builder /transmission-web-control  /transmission-web-control
COPY --from=builder /s6-config /

RUN \
 echo "**** setup web interface ****" && \
 mkdir /usr/local/share/transmission && \
 ln -s /web/ /usr/local/share/transmission/web && \
 ln -s /web/index.html /transmission-web-control/index.original.html && \
 ln -s /web/images/ /transmission-web-control/images && \
 ln -s /web/javascript/ /transmission-web-control/javascript && \
 ln -s /web/style/ /transmission-web-control/style

# ports and volumes
EXPOSE 9091 51413 51413/udp
VOLUME /config /downloads /watch
