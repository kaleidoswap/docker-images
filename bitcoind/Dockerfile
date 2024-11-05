FROM debian:buster-slim AS builder

ARG BITCOIN_VERSION="c23afab47fbe"
ARG TRIPLET="x86_64-linux-gnu"

ENV BITCOIN_DOWNLOAD_URL="https://github.com/benthecarman/bitcoin/releases/download/mutinynet-cat-lnhance/bitcoin-${BITCOIN_VERSION}-${TRIPLET}.tar.gz"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gosu \
        wget \
        tar \
        libc6 \
        procps \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /tmp

RUN wget -qO "bitcoin.tar.gz" "${BITCOIN_DOWNLOAD_URL}" && \
    mkdir -p bin && \
    tar -xzvf "bitcoin.tar.gz" -C /tmp/bin --strip-components=2 \
        "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-cli" \
        "bitcoin-${BITCOIN_VERSION}/bin/bitcoind" \
        "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-wallet" \
        "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-util" && \
    rm -rf /tmp/bin/bitcoin-${BITCOIN_VERSION} bitcoin.tar.gz

FROM debian:buster-slim

ENV PATH=/opt/bitcoin/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    APP_DIR=/srv/app \
    USER=bitcynic \
    INST_DIR=/opt/bitcoin \
    BITCOIN_DIR=/root/.bitcoin

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        procps \
        gosu \
        libc6 \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home ${APP_DIR} --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER} && \
    mkdir -p ${APP_DIR}/.bitcoin && \
    chown ${USER}:${USER} ${APP_DIR}/.bitcoin

COPY --from=builder "/tmp/bin" /opt/bitcoin/bin

COPY start-bitcoind.sh /usr/local/bin/start-bitcoind.sh

RUN chmod +x /usr/local/bin/start-bitcoind.sh

WORKDIR /srv/app

ENTRYPOINT ["/usr/local/bin/start-bitcoind.sh"]
