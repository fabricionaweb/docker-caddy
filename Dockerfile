# syntax=docker/dockerfile:1-labs
FROM public.ecr.aws/docker/library/alpine:3.19 AS base
ENV TZ=UTC
WORKDIR /src

# build stage ==================================================================
FROM base AS build-app
ENV CGO_ENABLED=0 GOBIN=/usr/local/bin

# dependencies
RUN apk add --no-cache git && \
    apk add --no-cache go --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community
ARG XVERSION=0.3.5
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@v$XVERSION

# build with desec
ARG VERSION
RUN xcaddy build v$VERSION \
    --with github.com/caddy-dns/desec \
    --with github.com/mholt/caddy-ratelimit \
    --output /build/caddy

# runtime stage ================================================================
FROM base

ENV S6_VERBOSITY=0 S6_BEHAVIOUR_IF_STAGE2_FAILS=2 PUID=65534 PGID=65534
ENV HOME=/config
WORKDIR /config
VOLUME /config
EXPOSE 80 443

# copy files
COPY --from=build-app /build /app
COPY ./rootfs/. /

# runtime dependencies
RUN apk add --no-cache tzdata s6-overlay

# run using s6-overlay
ENTRYPOINT ["/init"]
