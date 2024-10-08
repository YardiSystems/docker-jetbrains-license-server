# syntax=docker/dockerfile:1

ARG JLS_VERSION=39687
ARG JLS_SHA256=bcb5fa802993894c61bc4da96ffd823cbb90a3151ab4da57ae7cc8c4301d3eab
ARG ALPINE_VERSION=3.19

FROM alpine:${ALPINE_VERSION}


RUN apk update \
	&& apk add --no-cache ca-certificates \
    && apk add curl
COPY --from=harbork8s.yardiapp.com/base/ysi-base-commonfiles-linux:latest /common/files/ysifwcert01-ca.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

ENV JLS_PATH="/opt/jetbrains-license-server" \
  TZ="UTC" \
  PUID="1002" \
  PGID="1002" 
ARG JLS_SHA256
ARG JLS_VERSION
RUN apk add --update --no-cache \
    bash \
    ca-certificates \
    curl \
    openjdk11-jre \
    openssl \
    shadow \
    zip \
    tzdata \
  && mkdir -p /data "$JLS_PATH" \
  && curl "https://yum.yardi.com/packages/templates/jetbrains-fls/license-server-installer_$JLS_VERSION.zip" -o "/tmp/jls.zip" \
  && echo "$JLS_SHA256  /tmp/jls.zip" | sha256sum -c - | grep OK \
  && unzip "/tmp/jls.zip" -d "$JLS_PATH" \
  && rm -f "/tmp/jls.zip" \
  && chmod a+x "$JLS_PATH/bin/license-server.sh" \
  && ln -sf "$JLS_PATH/bin/license-server.sh" "/usr/local/bin/license-server" \
  && addgroup -g ${PGID} jls \
  && adduser -u ${PUID} -G jls -h /data -s /bin/bash -D jls \
  && chown -R jls. /data "$JLS_PATH" \
  && rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh

EXPOSE 8000
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]

HEALTHCHECK --interval=10s --timeout=5s \
  CMD license-server status || exit 1
