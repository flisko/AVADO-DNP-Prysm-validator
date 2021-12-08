
# build image for monitor & wizard
FROM node:12-alpine as builder-nodejs

# build wizard
WORKDIR /usr/src/wizard
COPY wizard .
RUN rm -Rf   node_modules
RUN rm -f yarn.lock
RUN yarn add react-scripts 
RUN yarn 
RUN yarn build


#TODO: DO NOT MERGE TO MASTER: use release $VERSION here instead
FROM  gcr.io/prysmaticlabs/prysm/validator:latest as builder

FROM debian:buster-slim


RUN apt update && \
    apt install -y ca-certificates nginx && \
    rm -rf /var/lib/apt/lists/*

WORKDIR  /usr/share/nginx
COPY --from=builder-nodejs /usr/src/wizard/build /usr/share/nginx/wizard
COPY files/nginx.conf /etc/nginx

COPY --from=builder /app/cmd/validator/validator /bin/validator


COPY files/start.sh /scripts/start.sh
RUN chmod +x /scripts/start.sh


ENTRYPOINT [ "/scripts/start.sh" ]

