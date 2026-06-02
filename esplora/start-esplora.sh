#!/bin/bash
# Start the MutinyWallet/electrs (Blockstream esplora fork) indexer.
# Serves the esplora HTTP REST API + electrum RPC, indexing a custom signet
# (Mutinynet) via --signet-magic. Reads blocks directly from the bitcoind
# datadir (mounted read-only) and talks to bitcoind RPC for the rest.

_die() { echo "$@" 1>&2; exit 2; }

# --- params (env, with sane defaults) ---
BTCHOST=${BTCHOST:-"bitcoind"}
BTCRPCPORT=${BTCRPCPORT:-"38332"}
BTCUSER=${BTCUSER:-"user"}
BTCPASS=${BTCPASS:-"default_password"}
HTTP_PORT=${HTTP_PORT:-"3000"}          # esplora REST
ELECTRUM_PORT=${ELECTRUM_PORT:-"50001"} # electrum RPC
MONITORING_PORT=${MONITORING_PORT:-"24224"}
NETWORK=${NETWORK:-"signet"}
SIGNET_MAGIC=${SIGNET_MAGIC:-""}
# bitcoind datadir mounted here (must contain the network's blocks/, e.g. signet/)
DAEMON_DIR=${DAEMON_DIR:-"/bitcoin"}
LOG_LEVEL=${LOG_LEVEL:-"info"}          # passed as -v count below

[[ ! "${NETWORK}" =~ ^(bitcoin|mainnet|testnet|regtest|signet|liquid)$ ]] && \
    _die "incorrect network: ${NETWORK}"

# fix ownership of writable dirs
[ -n "${MYUID}" ] && usermod -u "${MYUID}" "${USER}" 2>/dev/null || true
[ -n "${MYGID}" ] && groupmod -g "${MYGID}" "${USER}" 2>/dev/null || true
chown -R "${USER}:${USER}" "${APP_DIR}/db" 2>/dev/null || true

# verbosity: info=2 (-vv), debug=3 (-vvv)
case "${LOG_LEVEL}" in
  trace) V="-vvvv" ;; debug) V="-vvv" ;; info) V="-vv" ;; *) V="-v" ;;
esac

ARGS="--network ${NETWORK}"
[ -n "${SIGNET_MAGIC}" ] && ARGS="${ARGS} --signet-magic ${SIGNET_MAGIC}"
ARGS="${ARGS} --daemon-rpc-addr ${BTCHOST}:${BTCRPCPORT}"
ARGS="${ARGS} --cookie ${BTCUSER}:${BTCPASS}"
ARGS="${ARGS} --daemon-dir ${DAEMON_DIR}"
ARGS="${ARGS} --db-dir ${APP_DIR}/db"
ARGS="${ARGS} --http-addr 0.0.0.0:${HTTP_PORT}"
ARGS="${ARGS} --electrum-rpc-addr 0.0.0.0:${ELECTRUM_PORT}"
ARGS="${ARGS} --monitoring-addr 0.0.0.0:${MONITORING_PORT}"
# jsonrpc-import: fetch blocks via RPC instead of parsing blk*.dat off disk.
# The blk-files fetcher panics on Mutinynet ('failed to index N blocks from
# blk*.dat'); RPC import is robust (matches how the regtest esplora runs).
[ "${JSONRPC_IMPORT:-true}" = "true" ] && ARGS="${ARGS} --jsonrpc-import"
ARGS="${ARGS} --cors '*' ${V}"

cmd="${APP_DIR}/electrs ${ARGS} $@"
echo "Starting esplora: ${cmd}"
exec gosu "${USER}" ${APP_DIR}/electrs ${ARGS} "$@"
