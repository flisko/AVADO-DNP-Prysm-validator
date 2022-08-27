ARG VERSION

# build image for monitor & wizard
FROM node:16.14.0 as builder-nodejs

# build wizard
WORKDIR /usr/src/wizard
COPY wizard .
RUN rm -Rf   node_modules
RUN rm -f yarn.lock
RUN yarn add react-scripts 
RUN yarn 
RUN yarn run build

FROM --platform=linux/amd64 gcr.io/prysmaticlabs/prysm/validator:${VERSION} as builder

FROM --platform=linux/amd64 debian:buster-slim

RUN apt update && \
    apt install -y \
    ca-certificates \
    jq \
    nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR  /usr/share/nginx
COPY --from=builder-nodejs /usr/src/wizard/build /usr/share/nginx/wizard
COPY files/nginx.conf /etc/nginx

COPY --from=builder /app/cmd/validator/validator /bin/validator


COPY files/start.sh /scripts/start.sh
RUN chmod +x /scripts/start.sh


ENTRYPOINT [ "/scripts/start.sh" ]

