FROM alpine:3.12

RUN apk add --update --no-cache openssh openssl sshpass curl jq
COPY scripts/task.sh /usr/local/bin/tekton-orka
RUN chmod 755 /usr/local/bin/tekton-orka
