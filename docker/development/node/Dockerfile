FROM node:22-alpine

RUN apk add --no-cache \
    tzdata \
    envsubst \
    ca-certificates \
    wget \
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

