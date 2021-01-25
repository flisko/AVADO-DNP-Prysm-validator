FROM node as builder
ARG VERSION

WORKDIR /app/validator 
ENV DOWNLOAD_URL https://github.com/prysmaticlabs/prysm/releases/download
ENV BINARY_URL ${DOWNLOAD_URL}/${VERSION}/validator-${VERSION}-linux-amd64

RUN wget $BINARY_URL -O validator && \
    chmod +x  validator
RUN ls -l


FROM debian:buster-slim


RUN apt update && \
    apt install -y ca-certificates nginx && \
    rm -rf /var/lib/apt/lists/*

WORKDIR  /usr/share/nginx
COPY wizard ./wizard
COPY files/nginx.conf /etc/nginx

COPY --from=builder /app/validator/validator /bin/validator

COPY files/start.sh /scripts/start.sh
RUN chmod +x /scripts/start.sh


ENTRYPOINT [ "/scripts/start.sh" ]

