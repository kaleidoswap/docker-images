# Makefile for RGB Lightning Node Stack

# Default variables (can be overridden via environment)
COMPOSE=docker-compose

.PHONY: help full node-only build start stop down clean logs restart

help: ## Display this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make full       # Start the full stack"
	@echo "  make node-only  # Start only the RGB Lightning Node"
	@echo "  make logs       # View logs from all running services"

setup: ## Setup environment file from example if it doesn't exist
	@if [ ! -f .env ]; then \
		echo "Setting up .env file from .env.example..."; \
		cp .env.example .env; \
		echo ".env file created. You may want to edit it to customize your setup."; \
	else \
		echo ".env file already exists."; \
	fi

full: setup ## Start the full stack (Bitcoin Core, Electrs, RGB Proxy, RGB Lightning Node)
	$(COMPOSE) --profile full up -d

node-only: setup ## Start only the RGB Lightning Node (for connecting to external services)
	$(COMPOSE) --profile node-only up -d

build: ## Build all the Docker images locally
	$(COMPOSE) -f docker-compose.build.yml build

start: ## Start all services based on existing profiles
	$(COMPOSE) start

stop: ## Stop all running services without removing containers
	$(COMPOSE) stop

down: ## Stop and remove all containers, networks created by docker-compose
	$(COMPOSE) down

clean: down ## Remove all data (WARNING: This will delete all blockchain data)
	@echo "This will remove all data directories. Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	rm -rf ./data/*

logs: ## View logs from all services
	$(COMPOSE) logs -f

logs-bitcoind: ## View logs from the Bitcoin Core service
	$(COMPOSE) logs -f bitcoind

logs-electrs: ## View logs from the Electrs service
	$(COMPOSE) logs -f electrs

logs-proxy: ## View logs from the RGB Proxy service
	$(COMPOSE) logs -f proxy

logs-node: ## View logs from the RGB Lightning Node service
	$(COMPOSE) logs -f rln-node

restart: stop start ## Restart all services

# Default target when running make without arguments
.DEFAULT_GOAL := help