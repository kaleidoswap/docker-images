# Esplora HTTP REST indexer for Mutinynet (custom signet).
#
# Built from MutinyWallet's fork of Blockstream/electrs (the "new-index" /
# esplora backend) — the same engine that powers mutinynet.com/api. Unlike
# romanz/electrs (electrum-only, used by ../electrs), this serves the esplora
# HTTP REST API (--http-addr) AND supports a custom --signet-magic, so it can
# index Mutinynet's custom signet.

FROM rust:1.92.0-slim-trixie AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends clang cmake git build-essential libsnappy-dev

WORKDIR /tmp

ARG GIT_URL="https://github.com/MutinyWallet/electrs.git"
ARG GIT_REF="new-index"

RUN git clone -b ${GIT_REF} --depth 1 ${GIT_URL} \
    && cd electrs \
    && cargo build --release --bin electrs \
    && cp target/release/electrs /tmp/electrs-bin

FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends adduser gosu ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV APP_DIR="/srv/app" USER="blits"
RUN adduser --home ${APP_DIR} --shell /bin/bash --disabled-login \
    --gecos "${USER} user" ${USER}

WORKDIR "${APP_DIR}"

COPY --from=builder --chown=${USER}:${USER} /tmp/electrs-bin ./electrs

RUN mkdir -p ${APP_DIR}/db
COPY start-esplora.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-esplora.sh

# 3000 = esplora HTTP REST API, 50001 = electrum RPC, 24224 = monitoring
EXPOSE 3000 50001 24224
STOPSIGNAL SIGINT
VOLUME ["${APP_DIR}/db"]
ENTRYPOINT ["/usr/local/bin/start-esplora.sh"]
