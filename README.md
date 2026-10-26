# Docker Images for RGB Lightning Node Stack

This repository contains Docker images and configurations for running a complete RGB Lightning Node stack, with special support for Mutinynet (a custom Bitcoin Signet network).

## Components

### Core Images
Built from this repository:
- **bitcoind**: Custom Bitcoin Core build with Mutinynet support
- **electrs**: Electrum server implementation in Rust
- **esplora**: Esplora HTTP REST indexer (plus Electrum RPC) that can index Mutinynet

Used by the stack, but built elsewhere:
- **rgb-lightning-node**: RGB-enabled Lightning Network node (`kaleidoswap/rgb-lightning-node`)
- **rgb-proxy**: Proxy server for RGB protocol operations (`ghcr.io/rgb-tools/rgb-proxy-server`)

### Published Images

The [Build and Push Docker Images](.github/workflows/docker-publish.yml) workflow builds every image on pushes and pull requests to `main` and on `v*.*.*` tags, and pushes to Docker Hub (pull requests only build, they don't push):

| Image | Directory | Platforms |
|-------|-----------|-----------|
| `kaleidoswap/mutinynet-bitcoind` | `bitcoind/` | `linux/amd64`, `linux/arm64` |
| `kaleidoswap/mutinynet-electrs` | `electrs/` | `linux/amd64`, `linux/arm64` |
| `kaleidoswap/mutinynet-esplora` | `esplora/` | `linux/amd64` |

Tags:
- `latest` and `main`: the latest build of the `main` branch
- `sha-<short sha>`: a specific commit (e.g. `kaleidoswap/mutinynet-bitcoind:sha-3ea6874`)
- `<version>` and `<major>.<minor>`: from `v*.*.*` git tags

```bash
docker pull kaleidoswap/mutinynet-bitcoind:latest
docker pull kaleidoswap/mutinynet-electrs:latest
docker pull kaleidoswap/mutinynet-esplora:latest
```

## Deployment Options

You can run the RGB Lightning Node in two ways:

1. **Full Stack**: Run all components (Bitcoin Core, Electrs, RGB Proxy, RGB Lightning Node) locally
2. **Node Only**: Run only the RGB Lightning Node connected to external services

Choose the option that best suits your needs:
- Use **Full Stack** for development, testing, or when you need full control over the entire infrastructure
- Use **Node Only** when you want to connect to existing Bitcoin Core, Electrs, and RGB Proxy services

## Quick Start with Makefile

The easiest way to run the RGB Lightning Node stack is using the provided Makefile:

1. Clone the repository:

```bash
git clone https://github.com/kaleidoswap/docker-images.git
cd docker-images
```

2. Run one of the following commands:

```bash
# To see all available commands
make help

# To run the full stack
make full

# To run only the RGB Lightning Node
make node-only

# To view logs
make logs
```

The Makefile will automatically copy the `.env.example` to `.env` if it doesn't exist. You may want to edit this file to customize your setup.

## Option 1: Running the Full Stack

This runs all services locally, giving you a complete self-contained environment:

1. Clone the repository:

```bash
git clone https://github.com/kaleidoswap/docker-images.git
```

2. Configure your setup:

```bash
cd docker-images
cp .env.example .env  # Edit this file to customize your setup
```

3. Start all services:

```bash
make full
# OR with docker-compose directly:
docker-compose up -d
docker-compose --profile full up -d
```

This will start Bitcoin Core (configured for Mutinynet), Electrs, RGB Proxy, and the RGB Lightning Node.

## Option 2: Running Only the RGB Lightning Node

Use this option when you want to connect to external services:

1. Clone the repository:

```bash
git clone https://github.com/kaleidoswap/docker-images.git
cd docker-images
```

2. Configure external services in `.env`:

```bash
cp .env.example .env
```

3. Edit `.env` to set the RGB Lightning Node parameters and connection details for external services:

```
# Network configuration
NETWORK=signet  # Can be signet, testnet, or regtest

# RGB Lightning Node Settings
RLN_API_PORT=3001
RLN_PEER_PORT=9735
RLN_DATA_DIR=./data/rln-node

# External service connections (uncomment and configure)
# EXTERNAL_BITCOIND_RPC=--bitcoind-rpc http://user:password@host:port
# EXTERNAL_BITCOIND_P2P=--bitcoind-p2p host:port
# EXTERNAL_ELECTRS_URL=--electrum-url tcp://host:port
# EXTERNAL_PROXY_URL=--proxy-url http://host:port
```

4. Start only the RGB Lightning Node:

```bash
make node-only
# OR with docker-compose directly:
docker-compose --profile node-only up -d
```

This will start only the RGB Lightning Node, which will connect to the external services you've configured.

## Makefile Commands

The repository includes a Makefile to simplify common operations:

| Command        | Description                                                  |
|----------------|--------------------------------------------------------------|
| `make help`    | Display help message with all available commands             |
| `make full`    | Start the full stack (all services)                          |
| `make node-only` | Start only the RGB Lightning Node                           |
| `make setup`   | Create `.env` from `.env.example` if it doesn't exist        |
| `make build`   | Build all Docker images locally                              |
| `make start`   | Start existing containers                                    |
| `make logs`    | View logs from all services                                  |
| `make logs-bitcoind` | View logs from Bitcoin Core                            |
| `make logs-electrs` | View logs from Electrs                                  |
| `make logs-proxy` | View logs from the RGB Proxy                              |
| `make logs-node` | View logs from just the RGB Lightning Node                   |
| `make stop`    | Stop all running services                                    |
| `make down`    | Stop and remove all containers                               |
| `make clean`   | Remove all data (WARNING: This will delete all chain data)   |
| `make restart` | Restart all services                                         |

## Image Details

### Bitcoin Core (bitcoind)
- Based on Debian Bookworm (`debian:bookworm-slim`)
- Mutinynet build of Bitcoin Inquisition 29 ([benthecarman/bitcoin](https://github.com/benthecarman/bitcoin/releases/tag/mutinynet-inq-29) release `mutinynet-inq-29`, `BITCOIN_VERSION=38351585048e`)
- Configurable through environment variables
- Reference: 

dockerfile: [bitcoind/Dockerfile](bitcoind/Dockerfile)

### Electrs
- Rust-based Electrum server ([romanz/electrs](https://github.com/romanz/electrs) `v0.11.0`, set with the `GIT_REF` build arg)
- Built with Rust 1.92 and runs on Debian Trixie (`debian:trixie-slim`)
- Optimized for performance with RocksDB
- Supports Signet/Mutinynet
- Reference:

dockerfile: [electrs/Dockerfile](electrs/Dockerfile)

### Esplora
- Esplora HTTP REST API indexer, the same engine that powers `mutinynet.com/api`
- Built from [kaleidoswap/electrs](https://github.com/kaleidoswap/electrs) (`new-index` branch, pinned to a commit), our fork of MutinyWallet's fork of Blockstream/electrs
- Unlike the electrs image, it serves the esplora REST API and supports a custom `--signet-magic`, so it can index Mutinynet
- Adds `POST /txs/package`: a child with its unconfirmed parents is relayed to bitcoind's `submitpackage` (Bitcoin Core 28+), so a child's fee can carry a parent below the mempool minimum (CPFP)
- Imports blocks over RPC (`--jsonrpc-import`) by default; set `JSONRPC_IMPORT=false` to read `blk*.dat` files instead
- Built with Rust 1.69 on Debian Bullseye, using the Debian archive since Bullseye's EOL; the runtime image is Debian Trixie (`debian:trixie-slim`)
- `linux/amd64` only
- Ports: `3000` (esplora REST), `50001` (Electrum RPC), `24224` (monitoring)
- Configured through environment variables: `NETWORK`, `SIGNET_MAGIC`, `BTCHOST`, `BTCRPCPORT`, `BTCUSER`, `BTCPASS`, `DAEMON_DIR`, `HTTP_PORT`, `ELECTRUM_PORT`, `MONITORING_PORT`, `LOG_LEVEL`
- Reference:

dockerfile: [esplora/Dockerfile](esplora/Dockerfile)

To run it against a Mutinynet bitcoind reachable as `bitcoind` on the same Docker network (the bitcoind datadir is mounted read-only at `/bitcoin`):

```bash
docker run -d --name esplora --network <bitcoind network> \
  -e NETWORK=signet -e SIGNET_MAGIC=a5df2dcb \
  -e BTCHOST=bitcoind -e BTCRPCPORT=38332 -e BTCUSER=user -e BTCPASS=default_password \
  -v ./data/esplora:/srv/app/db -v ./data/bitcoin:/bitcoin:ro \
  -p 3000:3000 \
  kaleidoswap/mutinynet-esplora:latest
```

### RGB Lightning Node
- LDK-based Lightning implementation with RGB support
- Can be run standalone with external services
- Configurable through environment variables
- Supports connection to external Bitcoin Core, Electrs, and RGB Proxy services

## Development

To build the images locally:

```bash
make build
# OR with docker-compose directly:
docker-compose -f docker-compose.build.yml build
```

`docker-compose.build.yml` also defines the `esplora` service (it is not in `docker-compose.yml`). Its HTTP port is set with `ESPLORA_HTTP_PORT` in `.env`.

To build a single image:

```bash
docker build -t mutinynet-bitcoind ./bitcoind
docker build --build-arg GIT_REF=v0.11.0 -t mutinynet-electrs ./electrs
docker build --platform linux/amd64 -t mutinynet-esplora ./esplora
```

To test `POST /txs/package` end to end against a locally built esplora image (needs docker, curl and jq):

```bash
docker build -t kaleido-esplora-package:test esplora
IMG_ESP=kaleido-esplora-package:test esplora/test-package.sh
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on [Mutinynet](https://github.com/MutinyWallet/mutinynet)
- Uses [RGB Lightning Node](https://github.com/RGB-Tools/rgb-lightning-node)
- Electrs implementation from [romanz/electrs](https://github.com/romanz/electrs)
- Esplora indexer from [kaleidoswap/electrs](https://github.com/kaleidoswap/electrs), a fork of [MutinyWallet/electrs](https://github.com/MutinyWallet/electrs) and [Blockstream/electrs](https://github.com/Blockstream/electrs)
- Proxy server from [RGB-Tools/rgb-proxy-server](https://github.com/RGB-Tools/rgb-proxy-server)