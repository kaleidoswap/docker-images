FROM rust:1.71.0-slim-bookworm as builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    clang \
    cmake \
    git \
    libsnappy-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

ARG GIT_REF="v0.10.0"
ENV GIT_URL="https://github.com/romanz/electrs.git" \
    CARGO_NET_GIT_FETCH_WITH_CLI=true \
    CARGO_BUILD_JOBS=2 \
    RUST_BACKTRACE=full \
    CARGO_HOME=/tmp/cargo \
    CARGO_TARGET_DIR=/tmp/target

# Clone and build with optimized settings
RUN git clone -b ${GIT_REF} --depth 1 ${GIT_URL} && \
    cd electrs && \
    cargo build --locked --release --jobs 2 && \
    cp /tmp/target/release/electrs /tmp/

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV APP_DIR="/srv/app" USER="blits"
RUN adduser --home ${APP_DIR} --shell /bin/bash --disabled-login \
    --gecos "${USER} user" ${USER}

WORKDIR "${APP_DIR}"

COPY --from=builder --chown=${USER}:${USER} /tmp/electrs .

RUN mkdir -p /etc/electrs ${APP_DIR}/db
COPY start-electrs.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-electrs.sh

EXPOSE 50001 24224
STOPSIGNAL SIGINT
VOLUME ["${APP_DIR}/db"]
ENTRYPOINT ["/usr/local/bin/start-electrs.sh"]