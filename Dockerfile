FROM alpine:3.13

RUN apk add \
  --update \
  --no-cache \
  curl \
  jq \
  openssh \
  openssl \
  rsync \
  sshpass \
  yq
RUN curl \
  --output /usr/bin/kubectl \
  --location https://storage.googleapis.com/kubernetes-release/release/v1.18.8/bin/linux/amd64/kubectl \
  && chmod 755 /usr/bin/kubectl
COPY scripts/orka-full.sh /usr/local/bin/orka-full
COPY scripts/orka-init.sh /usr/local/bin/orka-init
COPY scripts/orka-deploy.sh /usr/local/bin/orka-deploy
COPY scripts/orka-cleanup.sh /usr/local/bin/orka-cleanup
COPY scripts/copy-script.sh /usr/local/bin/copy-script
RUN chmod 755 /usr/local/bin/*
