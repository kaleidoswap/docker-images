# Esplora HTTP REST indexer (plus Electrum RPC) for Mutinynet and other signets.
#
# Built from Blockstream/electrs (the "new-index" / esplora backend), pinned to
# a commit. It indexes over RPC (--jsonrpc-import), which never reads the
# network magic, so a custom signet such as Mutinynet needs no patch: its
# genesis block and address format are those of every signet. Upstream also
# has what the older MutinyWallet-based build had to add (POST /txs/package)
# and bounds RocksDB's memory (--db-block-cache-mb,
# --cache-index-filter-blocks, --db-write-buffer-size-mb), which the old
# build could not: its index/filter blocks grew on the heap with the index.

FROM rust:1.92-slim-trixie AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends clang libclang-dev cmake git build-essential libsnappy-dev pkg-config

WORKDIR /tmp

ARG GIT_URL="https://github.com/Blockstream/electrs.git"
# new-index, 2026-11-18. The full clone resolves the commit whatever the
# branch has moved on to since.
ARG GIT_COMMIT="6cad780be93835b962af735171fae872f9526503"

RUN git clone ${GIT_URL} electrs \
    && cd electrs \
    && git checkout ${GIT_COMMIT} \
    && cargo build --release --locked --bin electrs \
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

# 3000 = esplora HTTP REST API, 50001 = electrum RPC, 24224 = monitoring (Prometheus)
EXPOSE 3000 50001 24224
STOPSIGNAL SIGINT
VOLUME ["${APP_DIR}/db"]
ENTRYPOINT ["/usr/local/bin/start-esplora.sh"]
