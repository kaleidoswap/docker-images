# Esplora HTTP REST indexer for Mutinynet (custom signet).
#
# Built from kaleidoswap/electrs, our fork of MutinyWallet's fork of
# Blockstream/electrs (the "new-index" / esplora backend) — the same engine
# that powers mutinynet.com/api. Unlike romanz/electrs (electrum-only, used by
# ../electrs), this serves the esplora HTTP REST API (--http-addr) AND supports
# a custom --signet-magic, so it can index Mutinynet's custom signet.
#
# On top of MutinyWallet's last commit, our fork adds what it predates, ported
# from Blockstream/electrs:
# - POST /txs/package: a child with its unconfirmed parents relayed to
#   bitcoind's `submitpackage` (Bitcoin Core 28+), so a child's fee can carry
#   a parent below the mempool minimum (CPFP). The maker pushes stuck RGB HTLC
#   claims through with it.

# Rust pinned to the fork's era (MutinyWallet/electrs new-index, last commit
# 2023-04). Newer toolchains panic building its pinned proc-macro2 1.0.37.
FROM rust:1.69-slim-bullseye AS builder

# Debian 11 left LTS on 2026-08-31 and deb.debian.org no longer serves its
# security pocket, so the build stage installs its tools from the permanent
# archive instead. Only this throwaway stage runs bullseye; the runtime image
# below is trixie.
RUN sed -i -e '/bullseye-security/d' \
        -e 's|http://deb.debian.org/debian|http://archive.debian.org/debian|' \
        /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends clang cmake git build-essential libsnappy-dev

WORKDIR /tmp

ARG GIT_URL="https://github.com/kaleidoswap/electrs.git"
ARG GIT_REF="new-index"
# "rest: add POST /txs/package", pinned so a push to the fork can't change
# the image. The full clone fetches every branch, so the commit resolves
# whether or not it has merged into new-index yet.
ARG GIT_COMMIT="ab9242f787e40cbb2c4766ab567e191e537fd46a"

RUN git clone -b ${GIT_REF} ${GIT_URL} \
    && cd electrs \
    && git checkout ${GIT_COMMIT} \
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
