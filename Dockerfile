FROM alpine:3.12

RUN apk add --update --no-cache openssh openssl sshpass curl jq
WORKDIR /app
COPY task.sh script.sh ./

ENTRYPOINT ["/app/task.sh"]
