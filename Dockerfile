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
COPY scripts/task.sh /usr/local/bin/tekton-orka
RUN chmod 755 /usr/local/bin/tekton-orka
