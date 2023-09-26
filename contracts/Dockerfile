# syntax=docker.io/docker/dockerfile:1.4

# image to install contracts dependencies
FROM node:latest as dependencies-installer

WORKDIR /opt/contracts
COPY . .

RUN npm install

# final image that has compiled contracts
FROM ghcr.io/foundry-rs/foundry:latest

COPY --from=dependencies-installer /opt/contracts /opt/contracts

WORKDIR /opt/contracts

# compile contracts
RUN forge build

RUN mkdir deployments