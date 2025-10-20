# Slimified versions and alpine don't include ca-certificates for apt
FROM node:24-bookworm

RUN for file in /etc/apt/sources.list.d/*; do \
      sed -i 's/http:/https:/g' "$file"; \
    done

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]
ENV SHELL=bash

WORKDIR /app

# Remove all of the below if not using PNPM

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV PNPM_HOME=/usr/local/share/.pnpm-store
ENV PATH=$PNPM_HOME:$PATH

RUN mkdir -p $PNPM_HOME

RUN npm install -g npm@latest corepack@latest
RUN corepack enable pnpm
RUN corepack use pnpm@latest

RUN pnpm i -g npm-check-updates
