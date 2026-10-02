#!/bin/bash
# End to end check of POST /txs/package (kaleidoswap/electrs): the Mutinynet bitcoind
# image (Bitcoin Inquisition 29.1) on regtest and this esplora image. A parent
# and a child built by the wallet are submitted as a package, the way the
# maker's EsploraChainBackend does, and must land in bitcoind's mempool, be
# indexed by esplora at once, and be mined together.
#
#   docker build -t kaleido-esplora-package:test esplora
#   IMG_ESP=kaleido-esplora-package:test esplora/test-package.sh
#
# Needs docker, curl and jq. On arm64 hosts the amd64 bitcoind runs emulated.
set -euo pipefail

NET=pkg-e2e
BTC=pkg-bitcoind
ESP=pkg-esplora
IMG_BTC=kaleidoswap/mutinynet-bitcoind:sha-3ea6874
IMG_ESP=${IMG_ESP:-kaleido-esplora-package:test}

cleanup() { docker rm -f "$BTC" "$ESP" >/dev/null 2>&1 || true; docker network rm "$NET" >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup
docker network create "$NET" >/dev/null

docker run -d --name "$BTC" --network "$NET" --platform linux/amd64 \
  --entrypoint /opt/bitcoin/bin/bitcoind "$IMG_BTC" \
  -regtest -server -txindex -printtoconsole \
  -rpcbind=0.0.0.0 -rpcallowip=0.0.0.0/0 -rpcuser=user -rpcpassword=pass \
  -fallbackfee=0.0001 >/dev/null
cli() { docker exec "$BTC" /opt/bitcoin/bin/bitcoin-cli -regtest -rpcuser=user -rpcpassword=pass "$@"; }
for _ in $(seq 1 60); do cli getblockchaininfo >/dev/null 2>&1 && break; sleep 1; done
cli -version | head -1
cli createwallet w >/dev/null
ADDR=$(cli -rpcwallet=w getnewaddress)
cli generatetoaddress 101 "$ADDR" >/dev/null

docker run -d --name "$ESP" --network "$NET" -p 127.0.0.1:3999:3000 \
  --entrypoint /srv/app/electrs "$IMG_ESP" \
  --network regtest --jsonrpc-import --daemon-rpc-addr "$BTC:18443" \
  --cookie user:pass --daemon-dir /srv/app --db-dir /tmp/db \
  --http-addr 0.0.0.0:3000 --electrum-rpc-addr 0.0.0.0:50001 -vv >/dev/null
URL=http://127.0.0.1:3999
for _ in $(seq 1 120); do
  [ "$(curl -s "$URL/blocks/tip/height" || true)" = "101" ] && break; sleep 1
done
echo "esplora tip: $(curl -s "$URL/blocks/tip/height")"

# Parent at 1 sat/vB paying 1 BTC to ourselves, never broadcast on its own.
DEST=$(cli -rpcwallet=w getnewaddress)
PSBT=$(cli -rpcwallet=w walletcreatefundedpsbt '[]' "[{\"$DEST\":1}]" 0 '{"fee_rate":1}' | jq -r .psbt)
PSBT=$(cli -rpcwallet=w walletprocesspsbt "$PSBT" | jq -r .psbt)
PARENT=$(cli finalizepsbt "$PSBT" | jq -r .hex)
PARENT_TXID=$(cli decoderawtransaction "$PARENT" | jq -r .txid)
VOUT=$(cli decoderawtransaction "$PARENT" | jq -r --arg a "$DEST" '.vout[] | select(.scriptPubKey.address==$a) | .n')
SPK=$(cli decoderawtransaction "$PARENT" | jq -r ".vout[$VOUT].scriptPubKey.hex")

# Child spending it at a high fee (1 BTC in, 0.999 BTC out: 100,000 sat).
DEST2=$(cli -rpcwallet=w getnewaddress)
CHILD=$(cli createrawtransaction "[{\"txid\":\"$PARENT_TXID\",\"vout\":$VOUT}]" "[{\"$DEST2\":0.999}]")
CHILD=$(cli -rpcwallet=w signrawtransactionwithwallet "$CHILD" \
  "[{\"txid\":\"$PARENT_TXID\",\"vout\":$VOUT,\"scriptPubKey\":\"$SPK\",\"amount\":1}]" | jq -r .hex)
CHILD_TXID=$(cli decoderawtransaction "$CHILD" | jq -r .txid)

echo "--- child alone through POST /tx (its parent is unknown): refused"
curl -s -o /dev/stderr -w "HTTP %{http_code}\n" -X POST --data "$CHILD" "$URL/tx" || true

echo "--- malformed package: refused before bitcoind"
curl -s -w " HTTP %{http_code}\n" -X POST --data '["zz"]' "$URL/txs/package"

echo "--- parent + child through POST /txs/package"
REPLY=$(curl -s -X POST --data "[\"$PARENT\",\"$CHILD\"]" "$URL/txs/package")
echo "$REPLY" | jq -c '{package_msg, txs: [."tx-results"[] | {txid, error}]}'
[ "$(echo "$REPLY" | jq -r .package_msg)" = "success" ] || { echo "FAIL: package not accepted"; exit 1; }

echo "--- both in bitcoind's mempool, and indexed by esplora at once"
cli getrawmempool | jq -c --arg p "$PARENT_TXID" --arg c "$CHILD_TXID" '[index($p) != null, index($c) != null]'
curl -s "$URL/tx/$CHILD_TXID/status"; echo
curl -s "$URL/tx/$PARENT_TXID/status"; echo
# What the maker's tx_confirmations reads to tell "in the mempool" from "unknown".
curl -s "$URL/mempool/txids" | jq -c --arg p "$PARENT_TXID" --arg c "$CHILD_TXID"   '{parent_in_esplora_mempool: (index($p) != null), child_in_esplora_mempool: (index($c) != null)}'

echo "--- re-submitting the same package is accepted again (already in the mempool)"
curl -s -X POST --data "[\"$PARENT\",\"$CHILD\"]" "$URL/txs/package" | jq -c '{package_msg}'

echo "--- mined together"
cli generatetoaddress 1 "$ADDR" >/dev/null
sleep 3
curl -s "$URL/tx/$CHILD_TXID/status" | jq -c '{confirmed, block_height}'
echo PASS
