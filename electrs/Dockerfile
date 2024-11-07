FROM rust:1.71.0-slim-bookworm as builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends clang cmake git libsnappy-dev

WORKDIR /tmp

ARG GIT_REF="v0.10.0"
ENV GIT_URL="https://github.com/romanz/electrs.git"

# Set CARGO_NET_GIT_FETCH_WITH_CLI to improve memory usage
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
ENV CARGO_BUILD_JOBS=4

# Clone step
RUN git clone -b ${GIT_REF} --depth 1 ${GIT_URL}

# Build step
RUN cd electrs \
    && RUSTFLAGS="-C opt-level=2" cargo install --locked --path . --jobs 4

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends gosu \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV APP_DIR="/srv/app" USER="blits"
RUN adduser --home ${APP_DIR} --shell /bin/bash --disabled-login \
    --gecos "${USER} user" ${USER}

WORKDIR "${APP_DIR}"

COPY --from=builder --chown=${USER}:${USER} \
    /tmp/electrs/target/release/electrs .

RUN mkdir -p /etc/electrs ${APP_DIR}/db
COPY start-electrs.sh /usr/local/bin
RUN chmod +x /usr/local/bin/start-electrs.sh

EXPOSE 50001 24224
STOPSIGNAL SIGINT
VOLUME ["${APP_DIR}/db"]
ENTRYPOINT ["/usr/local/bin/start-electrs.sh"]