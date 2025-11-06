FROM node:25-alpine AS base

# Ensure HTTPS use in Alpine Package Keeper (APK)
RUN awk '/http:\/\// {print "ERROR: Non-HTTPS repo:", $0; exit 1}' /etc/apk/repositories

# Verify base image integrity
RUN apk --no-cache info ca-certificates && \
    test -d /etc/apk/keys/ && \
    test $(ls /etc/apk/keys/*.pub | wc -l) -gt 0

RUN apk update

RUN apk audit || { \
    echo "ERROR: Package integrity check failed!" >&2; exit 1; \
}

# Ensure SSL defaults before doing anything with NPM
RUN npm config set registry https://registry.npmjs.org/ && \
    npm config set strict-ssl true && \
    npm config get registry | grep -q "^https://" || { \
        echo "ERROR: NPM https registry check failed!" >&2; exit 1; \
    }


FROM base AS pnpm

WORKDIR /usr/src/app

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH

RUN npm install -g pnpm@latest-10
