#!/bin/bash

_die() {
    echo "$@" 1>&2;
    exit 2
}

# get params
BTCHOST=${BTCHOST:-"bitcoind"}
BTCRPCPORT=${BTCRPCPORT:-"38332"}
BTCP2PPORT=${BTCP2PPORT:-"38333"}
BTCUSER=${BTCUSER:-"user"}
BTCPASS=${BTCPASS:-"password"}
PORT=${PORT:-"60601"}
MONITORING_PORT=${MONITORING_PORT:-"34224"}
NETWORK=${NETWORK:-"signet"}
LOG_LEVEL=${LOG_LEVEL:-"info"}
SIGNET_MAGIC=${SIGNET_MAGIC:-"a5df2dcb"}

# check params
[[ ! "${NETWORK}" =~ ^(mainnet|testnet|regtest|signet)$ ]] && \
    _die "incorrect network; available networks: mainnet, testnet, regtest, signet"
[[ ! "${LOG_LEVEL}" =~ ^(trace|debug|info|warning)$ ]] && \
    _die "incorrect log level; available levels: trace, debug, info, warning"

# set ownership
echo "Setting file ownership..."
[ -n "${MYUID}" ] && usermod -u "${MYUID}" "${USER}"
[ -n "${MYGID}" ] && groupmod -g "${MYGID}" "${USER}"
find "${APP_DIR}" \( -not -uid $(id -u ${USER}) -or -not -gid $(id -g ${USER}) \) \
    -exec chown --silent "${USER}:${USER}" "{}" +

# create config file
[ "${NETWORK}" == "mainnet" ] && NETWORK="bitcoin"
[[ ! "${LOG_LEVEL}" =~ ^(trace|debug|info|warn|error)$ ]] && \
    _die "incorrect log level; available levels: trace, debug, info, warn, error"
cat <<EOF > /etc/electrs/config.toml
daemon_rpc_addr = "${BTCHOST}:${BTCRPCPORT}"
daemon_p2p_addr = "${BTCHOST}:${BTCP2PPORT}"
auth = "${BTCUSER}:${BTCPASS}"
network = "${NETWORK}"
electrum_rpc_addr = "0.0.0.0:${PORT}"
index_batch_size = 10
jsonrpc_import = true
log_filters = "${LOG_LEVEL}"
monitoring_addr = "0.0.0.0:${MONITORING_PORT}"
signet_magic = "${SIGNET_MAGIC}"
EOF

# construct command
cmd="${APP_DIR}/electrs run --db-dir ${APP_DIR}/db $@"

# start service
echo "Starting electrs: ${cmd}"
exec gosu "${USER}" ${cmd}
