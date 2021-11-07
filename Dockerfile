FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

ARG BUILD_DATE
ARG VERSION
ARG TRANSMISSION_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

ARG DEBIAN_FRONTEND="noninteractive"

RUN \
 echo "**** install packages ****" && \
 bash -c "cat > /etc/apt/sources.list" << EOF
 # 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
 deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
 # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
 deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
 # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
 deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
 # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
 deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
 # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
 EOF
 apt-get update && \
 apt-get install -y \
	ca-certificates \
	curl \
	findutils \
	jq \
	openssl \
	p7zip \
	python3 \
	rsync \
	tar \
	unrar \
	unzip && \
	build-essential \
	automake \
	autoconf \
	libtool \
	pkg-config \
	intltool \
	libcurl4-openssl-dev \
	libglib2.0-dev \
	libevent-dev \
	libminiupnpc-dev \
	libgtk-3-dev \
	libappindicator3-dev && \
 curl -o \
 	/tmp/transmission.zip -L \
	"https://github.com/liofee/transmission/archive/refs/tags/2.9.4-rc1.zip" && \
 unzip \
	/tmp/transmission.zip -d \
	/tmp/transmission && \
 cd tmp/Transmission && \
 mkdir build && \
 cd build && \
 cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && \
 make && \
 make install && \
 echo "**** install third party themes ****" && \
 curl -o \
	/tmp/combustion.zip -L \
	"https://github.com/Secretmapper/combustion/archive/release.zip" && \
 unzip \
	/tmp/combustion.zip -d \
	/ && \
 mkdir -p /tmp/twctemp && \
 TWCVERSION=$(curl -sX GET "https://api.github.com/repos/ronggang/transmission-web-control/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o \
	/tmp/twc.tar.gz -L \
	"https://github.com/ronggang/transmission-web-control/archive/${TWCVERSION}.tar.gz" && \
 tar xf \
	/tmp/twc.tar.gz -C \
	/tmp/twctemp --strip-components=1 && \
 mv /tmp/twctemp/src /transmission-web-control && \
 mkdir -p /kettu && \
 curl -o \
	/tmp/kettu.tar.gz -L \
	"https://github.com/endor/kettu/archive/master.tar.gz" && \
 tar xf \
	/tmp/kettu.tar.gz -C \
	/kettu --strip-components=1 && \
 curl -o \
	/tmp/flood-for-transmission.tar.gz -L \
	"https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz" && \
 tar xf \
	/tmp/flood-for-transmission.tar.gz -C \
	/ && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/*


# copy local files
COPY root/ /

# ports and volumes
EXPOSE 9091 51413/tcp 51413/udp
VOLUME /config /downloads /watch
