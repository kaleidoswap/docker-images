# Docker Images for RGB Lightning Node Stack

This repository contains Docker images and configurations for running a complete RGB Lightning Node stack, with special support for Mutinynet (a custom Bitcoin Signet network).

## Components

### Core Images
- **bitcoind**: Custom Bitcoin Core build with Mutinynet support
- **electrs**: Electrum server implementation in Rust
- **rgb-lightning-node**: RGB-enabled Lightning Network node
- **rgb-proxy**: Proxy server for RGB protocol operations

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
| `make build`   | Build all Docker images locally                              |
| `make logs`    | View logs from all services                                  |
| `make logs-node` | View logs from just the RGB Lightning Node                   |
| `make stop`    | Stop all running services                                    |
| `make down`    | Stop and remove all containers                               |
| `make clean`   | Remove all data (WARNING: This will delete all chain data)   |
| `make restart` | Restart all services                                         |

## Image Details

### Bitcoin Core (bitcoind)
- Based on Debian Buster
- Custom build with Mutinynet support
- Configurable through environment variables
- Reference: 

dockerfile: [Kaleidoswap/docker-images/bitcoind/Dockerfile](Kaleidoswap/docker-images/bitcoind/Dockerfile)

### Electrs
- Rust-based Electrum server
- Optimized for performance with RocksDB
- Supports Signet/Mutinynet
- Reference:

dockerfile: [Kaleidoswap/docker-images/electrs/Dockerfile](Kaleidoswap/docker-images/electrs/Dockerfile)

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on [Mutinynet](https://github.com/MutinyWallet/mutinynet)
- Uses [RGB Lightning Node](https://github.com/RGB-Tools/rgb-lightning-node)
- Electrs implementation from [romanz/electrs](https://github.com/romanz/electrs)
- Proxy server from [RGB-Tools/rgb-proxy-server](https://github.com/RGB-Tools/rgb-proxy-server)