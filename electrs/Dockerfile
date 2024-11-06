FROM rust:1.71.0-slim-bookworm as builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    clang \
    cmake \
    git \
    libsnappy-dev \
    curl \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Set environment variables
ARG GIT_REF="v0.10.0"
ENV GIT_URL="https://github.com/romanz/electrs.git" \
    CARGO_NET_GIT_FETCH_WITH_CLI=true \
    CARGO_BUILD_JOBS=2 \
    RUST_BACKTRACE=full \
    CARGO_HOME=/tmp/cargo \
    CARGO_TARGET_DIR=/tmp/target

# Install specific rust toolchain with retries
RUN rustup default stable && \
    rustup component add rustfmt && \
    rustup component add clippy && \
    cargo --version && \
    rustc --version

# Clone and build with optimized settings and retries
RUN --mount=type=cache,target=/tmp/cargo/registry \
    --mount=type=cache,target=/tmp/cargo/git \
    --mount=type=cache,target=/tmp/target \
    git clone -b ${GIT_REF} --depth 1 ${GIT_URL} && \
    cd electrs && \
    (for i in 1 2 3; do \
        cargo build --locked --release --jobs 2 && break || \
        if [ $i -lt 3 ]; then \
            echo "Retry attempt $i of 3" && \
            sleep 10; \
        else \
            exit 1; \
        fi \
    done) && \
    mkdir -p /tmp/bin && \
    cp /tmp/target/release/electrs /tmp/bin/

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV APP_DIR="/srv/app" USER="blits"
RUN adduser --home ${APP_DIR} --shell /bin/bash --disabled-login \
    --gecos "${USER} user" ${USER}

WORKDIR "${APP_DIR}"

# Copy the binary from the builder stage
COPY --from=builder --chown=${USER}:${USER} /tmp/bin/electrs .

RUN mkdir -p /etc/electrs ${APP_DIR}/db
COPY start-electrs.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-electrs.sh

EXPOSE 50001 24224
STOPSIGNAL SIGINT
VOLUME ["${APP_DIR}/db"]
ENTRYPOINT ["/usr/local/bin/start-electrs.sh"]