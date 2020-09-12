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
RUN curl \
  --output /usr/local/bin/kubectl \
  --location https://storage.googleapis.com/kubernetes-release/release/v1.16.1/bin/linux/amd64/kubectl
COPY scripts/orka-full.sh /usr/local/bin/orka-full
COPY scripts/orka-init.sh /usr/local/bin/orka-init
COPY scripts/orka-cleanup.sh /usr/local/bin/orka-cleanup
COPY scripts/copy-script.sh /usr/local/bin/copy-script
RUN chmod 755 /usr/local/bin/*
