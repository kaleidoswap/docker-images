# Docker Images for RGB Lightning Node Stack

This repository contains Docker images and configurations for running a complete RGB Lightning Node stack, with special support for Mutinynet (a custom Bitcoin Signet network).

## Components

### Core Images
- **bitcoind**: Custom Bitcoin Core build with Mutinynet support
- **electrs**: Electrum server implementation in Rust
- **rgb-lightning-node**: RGB-enabled Lightning Network node
- **rgb-proxy**: Proxy server for RGB protocol operations

## Quick Start

1. Clone the repository:

```bash
git clone https://github.com/kaleidoswap/docker-images.git
```
2. Start the stack using docker-compose:

```bash
cd docker-images
docker-compose up -d
```

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


## Development

To build the images locally:

```bash
docker-compose -f docker-compose.build.yml build
```
## License

This project is licensed under the MIT License - see the LICENSE file for details.


## Acknowledgments

- Based on [Mutinynet](https://github.com/MutinyWallet/mutinynet)
- Uses [RGB Lightning Node](https://github.com/RGB-Tools/rgb-lightning-node)
- Electrs implementation from [romanz/electrs](https://github.com/romanz/electrs)
- Proxy server from [RGB-Tools/rgb-proxy-server](https://github.com/RGB-Tools/rgb-proxy-server)