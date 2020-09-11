FROM alpine:3.12

RUN apk add \
  --update \
  --no-cache \
  curl \
  jq \
  openssh \
  openssl \
  rsync \
  sshpass
COPY scripts/orka-full.sh /usr/local/bin/orka-full
COPY scripts/orka-init.sh /usr/local/bin/orka-init
COPY scripts/copy-script.sh /usr/local/bin/copy-script
RUN chmod 755 /usr/local/bin/*
