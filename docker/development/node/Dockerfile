ARG NODE_VERSION=24

FROM node:${NODE_VERSION}-alpine

RUN apk add --no-cache \
    tzdata \
    ca-certificates \
    curl \
    bash \
    nano \
    make \
    git \
    rsync

WORKDIR /app

ARG HOST_USER_ID=1000
ARG HOST_GROUP_ID=1000

RUN deluser --remove-home node \
  && addgroup -S node -g ${HOST_GROUP_ID} \
  && adduser -S -G node -u ${HOST_USER_ID} node

USER node

ARG VITE_PORT=8080

EXPOSE ${VITE_PORT}
