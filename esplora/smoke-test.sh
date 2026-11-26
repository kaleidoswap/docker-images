#!/usr/bin/env bash
# Smoke test for the esplora image: a regtest bitcoind, the image indexing it
# over RPC, and the REST routes our clients depend on.
#   esplora/smoke-test.sh <esplora image>
set -euo pipefail

IMAGE=${1:?usage: smoke-test.sh <esplora image>}
NET=esplora-smoke
BTC=esplora-smoke-bitcoind
ESP=esplora-smoke-esplora

cleanup() { docker rm -f "$BTC" "$ESP" >/dev/null 2>&1 || true; docker network rm "$NET" >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup
docker network create "$NET" >/dev/null

docker run -d --name "$BTC" --network "$NET" bitcoin/bitcoin:29.2 \
  -regtest -server -txindex -fallbackfee=0.0002 -rpcbind=0.0.0.0 -rpcallowip=0.0.0.0/0 \
  -rpcuser=smoke -rpcpassword=smoke -rpcport=18443 >/dev/null
cli() { docker exec "$BTC" bitcoin-cli -regtest -rpcuser=smoke -rpcpassword=smoke -rpcport=18443 "$@"; }
for _ in $(seq 30); do cli getblockchaininfo >/dev/null 2>&1 && break; sleep 1; done
cli createwallet smoke >/dev/null
ADDR=$(cli getnewaddress)
cli generatetoaddress 110 "$ADDR" >/dev/null
cli sendtoaddress "$ADDR" 1 >/dev/null
cli generatetoaddress 1 "$ADDR" >/dev/null

docker run -d --name "$ESP" --network "$NET" -p 127.0.0.1:3000:3000 \
  -e NETWORK=regtest -e BTCHOST="$BTC" -e BTCRPCPORT=18443 -e BTCUSER=smoke -e BTCPASS=smoke \
  -e SIGNET_MAGIC=a5df2dcb \
  "$IMAGE" >/dev/null

TIP=$(cli getblockcount)
for _ in $(seq 120); do
  [ "$(curl -fsS localhost:3000/blocks/tip/height 2>/dev/null || true)" = "$TIP" ] && break
  sleep 1
done
fail() { echo "FAIL: $*"; docker logs "$ESP" 2>&1 | tail -40; exit 1; }
[ "$(curl -fsS localhost:3000/blocks/tip/height)" = "$TIP" ] || fail "tip height is not $TIP"
curl -fsS localhost:3000/fee-estimates | grep -q '^{' || fail "/fee-estimates"
curl -fsS "localhost:3000/address/$ADDR/utxo" | grep -q '"txid"' || fail "/address/:a/utxo"
CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST -d '[]' localhost:3000/txs/package)
[ "$CODE" != 404 ] || fail "POST /txs/package is missing"
ORIGIN=$(curl -fsS -D - -o /dev/null localhost:3000/blocks/tip/height | tr -d '\r' | awk -F': ' 'tolower($1)=="access-control-allow-origin"{print $2}')
[ "$ORIGIN" = "*" ] || fail "Access-Control-Allow-Origin is '$ORIGIN'"
docker logs "$ESP" 2>&1 | grep -q -- '--cache-index-filter-blocks' || fail "memory flags not passed"
echo "OK: tip $TIP, fee-estimates, utxo, txs/package ($CODE), CORS, memory flags"
