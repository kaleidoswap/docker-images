FROM rust:1.71.0-slim-bookworm as builder

# Combine RUN commands and clean up in the same layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        clang \
        cmake \
        git \
        libsnappy-dev \
        curl \
        pkg-config && \
    rm -rf /var/lib/apt/lists/* && \
    # Install rust toolchain
    rustup default stable && \
    rustup component add rustfmt clippy && \
    # Clean cargo cache
    rm -rf /usr/local/cargo/registry

WORKDIR /tmp

# Set environment variables
ARG GIT_REF="v0.10.0"
ENV GIT_URL="https://github.com/romanz/electrs.git" \
    CARGO_NET_GIT_FETCH_WITH_CLI=true \
    RUST_BACKTRACE=full \
    CARGO_HOME=/tmp/cargo \
    CARGO_TARGET_DIR=/tmp/target

# Optimize build process
RUN --mount=type=cache,target=/tmp/cargo/registry \
    --mount=type=cache,target=/tmp/cargo/git \
    --mount=type=cache,target=/tmp/target \
    git clone -b ${GIT_REF} --depth 1 ${GIT_URL} && \
    cd electrs && \
    cargo build --locked --release && \
    mkdir -p /tmp/bin && \
    cp /tmp/target/release/electrs /tmp/bin/

FROM debian:bookworm-slim AS runtime

# Combine RUN commands to reduce layers
RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Create user and directories in the same layer
    adduser --home /srv/app --shell /bin/bash --disabled-login \
        --gecos "blits user" blits && \
    mkdir -p /etc/electrs /srv/app/db && \
    chown -R blits:blits /srv/app/db /etc/electrs

# Copy the binary from the builder stage
COPY --from=builder --chown=blits:blits /tmp/bin/electrs /srv/app/

# Add missing environment variables
ENV USER=blits \
    APP_DIR=/srv/app

# Fix directory creation (remove duplicate)
RUN mkdir -p /etc/electrs
COPY start-electrs.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-electrs.sh

# Fix volume permissions
RUN mkdir -p /srv/app/db /etc/electrs && \
    chown -R blits:blits /srv/app /etc/electrs

VOLUME ["/srv/app/db"]

EXPOSE 50001 24224
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/local/bin/start-electrs.sh"]