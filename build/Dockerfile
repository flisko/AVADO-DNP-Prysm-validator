#TODO: DO NOT MERGE TO MASTER: use release $VERSION here instead
FROM  gcr.io/prysmaticlabs/prysm/validator:latest as builder

FROM debian:buster-slim


RUN apt update && \
    apt install -y ca-certificates nginx && \
    rm -rf /var/lib/apt/lists/*

WORKDIR  /usr/share/nginx
COPY wizard ./wizard
COPY files/nginx.conf /etc/nginx

COPY --from=builder /app/cmd/validator/validator /bin/validator

COPY files/start.sh /scripts/start.sh
RUN chmod +x /scripts/start.sh


ENTRYPOINT [ "/scripts/start.sh" ]

