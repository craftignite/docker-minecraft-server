FROM adoptopenjdk:8-jre-hotspot

LABEL org.opencontainers.image.authors="Geoff Bourne <itzgeoff@gmail.com>; Twometer <twometer@outlook.de>"

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive \
  apt-get install -y \
    imagemagick \
    gosu \
    sudo \
    net-tools \
    curl wget \
    git \
    jq \
    dos2unix \
    mysql-client \
    tzdata \
    rsync \
    nano \
    unzip \
    knockd \
    ttf-dejavu \
    && apt-get clean

RUN addgroup --gid 1000 minecraft \
  && adduser --system --shell /bin/false --uid 1000 --ingroup minecraft --home /data minecraft

COPY files/sudoers* /etc/sudoers.d

EXPOSE 25565 25575

# hook into docker BuildKit --platform support
# see https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

ARG EASY_ADD_VER=0.7.1
ADD https://github.com/itzg/easy-add/releases/download/${EASY_ADD_VER}/easy-add_${TARGETOS}_${TARGETARCH}${TARGETVARIANT} /usr/bin/easy-add
RUN chmod +x /usr/bin/easy-add

# Install itzg/restify
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
  --var version=1.2.0 --var app=restify --file {{.app}} \
  --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

# Install itzg/rcon-cli
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=1.4.7 --var app=rcon-cli --file {{.app}} \
 --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

# Install itzg/mc-monitor
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=0.7.1 --var app=mc-monitor --file {{.app}} \
 --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

# Install itzg/maven-metadata-release
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=0.1.1 --var app=maven-metadata-release --file {{.app}} \
 --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

# Install craftignite/mc-server-runner
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=1.5.2 --var app=mc-server-runner --file {{.app}} \
 --from https://github.com/craftignite/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

# Install craftignite/craftignite-core
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
 --var version=0.3.0 --var app=craftignite-core --file {{.app}} \
 --from https://github.com/craftignite/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

COPY mcstatus /usr/local/bin

VOLUME ["/data"]
COPY server.properties /tmp/server.properties
COPY log4j2.xml /tmp/log4j2.xml
WORKDIR /data

STOPSIGNAL SIGTERM

ENV UID=1000 GID=1000 \
  MEMORY="1G" \
  TYPE=VANILLA VERSION=LATEST \
  ENABLE_RCON=true RCON_PORT=25575 RCON_PASSWORD=minecraft \
  SERVER_PORT=25565 INTERNAL_SERVER_PORT=25566 ONLINE_MODE=TRUE SERVER_NAME="Dedicated Server" \
  ENABLE_AUTOPAUSE=false AUTOPAUSE_TIMEOUT_EST=3600 AUTOPAUSE_TIMEOUT_KN=120 AUTOPAUSE_TIMEOUT_INIT=600 \
  AUTOPAUSE_PERIOD=10 AUTOPAUSE_KNOCK_INTERFACE=eth0 CRAFTIGNITE_NAME=craftignite-core CRAFTIGNITE_TIMEOUT=60 \
  CRAFTIGNITE_MOTD="§6CraftIgnite Minecraft Proxy\n§7Server is currently sleeping" \
  CRAFTIGNITE_KICK_MESSAGE="§l§6CraftIgnite\n\n§rThe server is currently starting.\nPlease try to reconnect in a minute." \
  CRAFTIGNITE_TOOLTIP_MESSAGE="§aServer will automatically start once you join"

COPY start* /
COPY health.sh /
ADD files/autopause /autopause

RUN dos2unix /start* && chmod +x /start*
RUN dos2unix /health.sh && chmod +x /health.sh
RUN dos2unix /autopause/* && chmod +x /autopause/*.sh


ENTRYPOINT [ "/start" ]

# Disable the healthcheck for now, since it will interfere with the automatic shutdown
# HEALTHCHECK --start-period=1m CMD /health.sh
