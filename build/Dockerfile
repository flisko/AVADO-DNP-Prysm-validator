ARG VERSION

# build image for monitor & wizard
FROM node:18.15.0 as builder

# build wizard
WORKDIR /usr/src/wizard
COPY wizard .
RUN rm -Rf node_modules
RUN rm -f yarn.lock
RUN yarn add react-scripts 
RUN yarn 
RUN yarn run build

# Monitor
WORKDIR /usr/src/monitor
COPY monitor .
RUN yarn --frozen-lockfile
RUN rm -Rf build && yarn run build
RUN rm -Rf node_modules
RUN yarn --production

FROM --platform=linux/amd64 gcr.io/prysmaticlabs/prysm/validator:${VERSION} as validator
FROM --platform=linux/amd64 gcr.io/prysmaticlabs/prysm/cmd/prysmctl:latest as prysmctl
 
FROM --platform=linux/amd64 node:18.15.0

RUN apt update && \
    apt install -y \
    ca-certificates \
    jq \
    nginx \
    supervisor \
    openssl\
    && rm -rf /var/lib/apt/lists/*

WORKDIR  /usr/share/nginx
COPY files/nginx.conf /etc/nginx

# copy wizard & monitor
COPY --from=builder /usr/src/wizard/build /usr/share/nginx/wizard
COPY --from=builder /usr/src/monitor/ /usr/local/monitor

COPY --from=validator /app/cmd/validator/validator /bin/validator
COPY --from=prysmctl /app/cmd/prysmctl/prysmctl.runfiles/prysm/cmd/prysmctl/prysmctl_/prysmctl /bin/prysmctl

COPY monitor/settings/defaultsettings.json /defaultsettings.json

COPY files/start.sh /scripts/start.sh
RUN chmod +x /scripts/start.sh

COPY supervisord.conf /etc/supervisord.conf

WORKDIR /
ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]

