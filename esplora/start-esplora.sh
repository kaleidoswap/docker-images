#!/bin/bash
# Start the Blockstream/electrs (esplora backend) indexer.
# Serves the esplora HTTP REST API + electrum RPC. Blocks come over bitcoind's
# RPC (--jsonrpc-import), so any signet works, Mutinynet included.

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
# RocksDB memory. The defaults bound a synced indexer to roughly
# block cache + 2 x 3 x write buffer (~1.4 GB). An initial sync runs faster
# with a bigger block cache (4096+).
DB_BLOCK_CACHE_MB=${DB_BLOCK_CACHE_MB:-1024}
DB_WRITE_BUFFER_SIZE_MB=${DB_WRITE_BUFFER_SIZE_MB:-64}
CACHE_INDEX_FILTER_BLOCKS=${CACHE_INDEX_FILTER_BLOCKS:-true}
# Optional bitcoind ZMQ hashblock socket (ip:port, e.g. 172.30.20.10:29000):
# new blocks are picked up at once instead of on the next poll.
ZMQ_ADDR=${ZMQ_ADDR:-""}
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
# SIGNET_MAGIC is accepted and ignored: RPC import does not need the magic,
# and upstream has no --signet-magic.
[ -n "${SIGNET_MAGIC:-}" ] && echo "SIGNET_MAGIC=${SIGNET_MAGIC} ignored: indexing over RPC needs no magic"
ARGS="${ARGS} --daemon-rpc-addr ${BTCHOST}:${BTCRPCPORT}"
ARGS="${ARGS} --cookie ${BTCUSER}:${BTCPASS}"
ARGS="${ARGS} --daemon-dir ${DAEMON_DIR}"
ARGS="${ARGS} --db-dir ${APP_DIR}/db"
ARGS="${ARGS} --http-addr 0.0.0.0:${HTTP_PORT}"
ARGS="${ARGS} --electrum-rpc-addr 0.0.0.0:${ELECTRUM_PORT}"
ARGS="${ARGS} --monitoring-addr 0.0.0.0:${MONITORING_PORT}"
ARGS="${ARGS} --db-block-cache-mb ${DB_BLOCK_CACHE_MB} --db-write-buffer-size-mb ${DB_WRITE_BUFFER_SIZE_MB}"
[ "${CACHE_INDEX_FILTER_BLOCKS}" = "true" ] && ARGS="${ARGS} --cache-index-filter-blocks"
[ -n "${ZMQ_ADDR}" ] && ARGS="${ARGS} --zmq-addr ${ZMQ_ADDR}"
# jsonrpc-import: fetch blocks via RPC instead of parsing blk*.dat off disk.
# The blk-files reader needs the network magic, which a custom signet does not
# share with the default one; RPC import works on any signet.
[ "${JSONRPC_IMPORT:-true}" = "true" ] && ARGS="${ARGS} --jsonrpc-import"
ARGS="${ARGS} ${V}"
# --cors is passed as its own quoted word: inside ARGS the quotes reached
# electrs literally (Access-Control-Allow-Origin: '*', rejected by browsers),
# and an unquoted * would glob.
CORS="${CORS:-*}"

cmd="${APP_DIR}/electrs ${ARGS} --cors ${CORS} $@"
echo "Starting esplora: ${cmd}"
exec gosu "${USER}" ${APP_DIR}/electrs ${ARGS} --cors "${CORS}" "$@"
