#!/bin/bash

_die() {
    echo "$@" 1>&2
    exit 2
}

# Ensure mandatory variables are set
: "${NETWORK?Need to set NETWORK}"
: "${RPCAUTH?Need to set RPCAUTH}"
: "${SIGNETCHALLENGE?Need to set SIGNETCHALLENGE}"
: "${ADDNODE?Need to set ADDNODE}"
: "${SIGNETBLOCKTIME?Need to set SIGNETBLOCKTIME}"

ADDR_TYPE=${ADDR_TYPE:-"bech32"}
DNSSEED=${DNSSEED:-0}

# Check params
[[ ! "${NETWORK}" =~ ^(mainnet|testnet|regtest|signet)$ ]] && \
    _die "incorrect network; available networks: mainnet, testnet, regtest, signet"

# Set ownership
echo "Setting file ownership..."
[ -n "${MYUID}" ] && usermod -u "${MYUID}" "${USER}"
[ -n "${MYGID}" ] && groupmod -g "${MYGID}" "${USER}"
find "${APP_DIR}" \( -not -uid $(id -u ${USER}) -or -not -gid $(id -g ${USER}) \) \
    -exec chown --silent "${USER}:${USER}" "{}" +

# Construct command with additional parameters
cmd="bitcoind -server -printtoconsole -txindex -onlynet=ipv4 -prune=0 \
    -rpcbind=0.0.0.0 \
    -rpcport=38332 \
    -rpcauth=${RPCAUTH} \
    -rpcallowip=0.0.0.0/0 \
    -zmqpubrawtx=tcp://0.0.0.0:28333 \
    -zmqpubrawblock=tcp://0.0.0.0:28332 \
    -zmqpubhashblock=tcp://0.0.0.0:29000 \
    -addresstype=${ADDR_TYPE} \
    -signetchallenge=${SIGNETCHALLENGE} \
    -addnode=${ADDNODE} \
    -dnsseed=${DNSSEED} \
    -signetblocktime=${SIGNETBLOCKTIME}"

[[ "${NETWORK}" =~ ^(testnet|regtest|signet)$ ]] && \
    cmd="${cmd} -${NETWORK}"

# Start service
echo "Starting bitcoind: ${cmd}"
exec gosu "${USER}" ${cmd}
