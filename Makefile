# Makefile for CR3 to DNG Converter Podman Setup

.PHONY: help build up down dry-run logs clean test

# Default target
help:
	@echo "CR3 to DNG Converter - Podman Commands"
	@echo ""
	@echo "Available commands:"
	@echo "  make build     - Build the Podman image"
	@echo "  make dry-run   - Run in dry-run mode (test what would be converted)"
	@echo "  make convert   - Run the actual conversion"
	@echo "  make logs      - Show container logs"
	@echo "  make clean     - Clean up containers and images"
	@echo "  make test      - Test the Podman setup"
	@echo ""
	@echo "Configuration:"
	@echo "  Copy .env.example to .env and edit paths"
	@echo "  Or set environment variables:"
	@echo "    export SOURCE_PATH=/path/to/cr3/files"
	@echo "    export DEST_PATH=/path/to/dng/output"

# Build the Podman image
build:
	@echo "Building CR3 to DNG converter Podman image..."
	podman-compose build

# Run in dry-run mode
dry-run:
	@echo "Running in dry-run mode..."
	podman-compose --profile dry-run up cr3-to-dng-converter-dry-run

# Run the actual conversion
convert:
	@echo "Starting CR3 to DNG conversion..."
	podman-compose up cr3-to-dng-converter

# Show logs
logs:
	podman-compose logs

# Clean up
clean:
	@echo "Cleaning up containers and images..."
	podman-compose down --rmi all --volumes --remove-orphans
	podman system prune -f

# Test the setup
test:
	@echo "Testing Podman setup..."
	@echo "Checking if .env file exists..."
	@if [ ! -f .env ]; then \
		echo "⚠️  No .env file found. Copy .env.example to .env and configure paths."; \
		echo "   cp .env.example .env"; \
		exit 1; \
	fi
	@echo "✅ .env file found"
	@echo "Building image..."
	podman-compose build
	@echo "✅ Build successful"
	@echo "Running dry-run test..."
	podman-compose --profile dry-run run --rm cr3-to-dng-converter-dry-run
	@echo "✅ Test completed"

# Alternative targets for direct podman commands (when podman-compose is not available)
build-podman:
	@echo "Building with direct podman command..."
	podman build -t cr3-to-dng-converter .

dry-run-podman:
	@echo "Running dry-run with direct podman command..."
	@if [ -z "$(SOURCE_PATH)" ] || [ -z "$(DEST_PATH)" ]; then \
		echo "⚠️  Please set SOURCE_PATH and DEST_PATH environment variables"; \
		echo "   export SOURCE_PATH=/path/to/cr3/files"; \
		echo "   export DEST_PATH=/path/to/dng/output"; \
		exit 1; \
	fi
	podman run --rm \
		-v "$(SOURCE_PATH):/photos/landing:ro,Z" \
		-v "$(DEST_PATH):/photos/converted:Z" \
		cr3-to-dng-converter --dry-run

convert-podman:
	@echo "Running conversion with direct podman command..."
	@if [ -z "$(SOURCE_PATH)" ] || [ -z "$(DEST_PATH)" ]; then \
		echo "⚠️  Please set SOURCE_PATH and DEST_PATH environment variables"; \
		echo "   export SOURCE_PATH=/path/to/cr3/files"; \
		echo "   export DEST_PATH=/path/to/dng/output"; \
		exit 1; \
	fi
	podman run --rm \
		-v "$(SOURCE_PATH):/photos/landing:ro,Z" \
		-v "$(DEST_PATH):/photos/converted:Z" \
		cr3-to-dng-converter

# Setup - copy example env file
setup:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file from template"; \
		echo "Please edit .env file to set your photo directories"; \
	else \
		echo "⚠️  .env file already exists"; \
	fi