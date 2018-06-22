FROM docker/compose:1.21.1

RUN apk add curl && rm -rf /var/cache/apk/*

ENTRYPOINT [ "/bin/sh" ]
