# CR3 to DNG Converter - Podman Setup

A Podman-based solution for converting Canon CR3 raw files to DNG format using dnglab.

## Features

- Convert CR3 files to DNG format while preserving folder structure
- Podman containerization for easy deployment and dependency management
- Configurable source and destination directories via environment variables
- Built-in dry-run mode for testing
- Uses the latest dnglab binary for optimal performance
- Rootless container support with Podman (more secure than Docker)
- SELinux-compatible volume mounts

## Prerequisites

- Podman
- podman-compose (optional, but recommended)

### Installing podman-compose

If you don't have podman-compose installed:

```bash
# On most Linux distributions
pip3 install podman-compose

# Or using system package manager (example for Fedora/RHEL)
sudo dnf install podman-compose

# On Ubuntu/Debian
sudo apt install podman-compose
```

## Quick Start

### Option 1: Use Pre-built Image from GitHub Container Registry

```bash
# Pull the latest image
podman pull ghcr.io/peterhenell/auto-convert-photos:latest

# Run conversion directly
podman run --rm \
  -v "/path/to/cr3/files:/photos/landing:ro,Z" \
  -v "/path/to/converted:/photos/converted:Z" \
  ghcr.io/peterhenell/auto-convert-photos:latest

# Run dry-run
podman run --rm \
  -v "/path/to/cr3/files:/photos/landing:ro,Z" \
  -v "/path/to/converted:/photos/converted:Z" \
  ghcr.io/peterhenell/auto-convert-photos:latest --dry-run
```

### Option 2: Build Your Own Image

### 1. Build the Podman Image

```bash
make build
# or directly: podman-compose build
```

### 2. Set Your Photo Directories

Create a `.env` file in the project directory to specify your photo directories:

```bash
# .env file
SOURCE_PATH=/path/to/your/cr3/photos
DEST_PATH=/path/to/converted/dng/photos
```

Or export environment variables:

```bash
export SOURCE_PATH="/path/to/your/cr3/photos"
export DEST_PATH="/path/to/converted/dng/photos"
```

### 3. Run Conversion

#### Dry Run (Recommended First)
Test what files would be converted without actually converting them:

```bash
make dry-run
# or: podman-compose --profile dry-run up cr3-to-dng-converter-dry-run
```

#### Actual Conversion
Convert all CR3 files:

```bash
make convert
# or: podman-compose up cr3-to-dng-converter
```

## Usage Options

### Using Environment Variables

```bash
SOURCE_PATH="/mnt/photos/raw" DEST_PATH="/mnt/photos/dng" podman-compose up
```

### Using Podman Run Directly (without podman-compose)

```bash
# Build the image
podman build -t cr3-to-dng-converter .

# Run dry-run
podman run --rm \
  -v "/path/to/source:/photos/landing:ro,Z" \
  -v "/path/to/destination:/photos/converted:Z" \
  cr3-to-dng-converter --dry-run

# Run actual conversion
podman run --rm \
  -v "/path/to/source:/photos/landing:ro,Z" \
  -v "/path/to/destination:/photos/converted:Z" \
  cr3-to-dng-converter
```

### Using Make Commands (Recommended)

```bash
# Setup
make setup          # Copy .env.example to .env
make build          # Build image
make dry-run        # Test conversion
make convert        # Run conversion

# Alternative direct podman commands
make build-podman   # Build with podman directly
make dry-run-podman # Dry run with podman directly  
make convert-podman # Convert with podman directly
```

## Configuration

### Environment Variables

- `SRC_DIR`: Source directory path inside the container (default: `/photos/landing`)
- `DST_DIR`: Destination directory path inside the container (default: `/photos/converted`)
- `SOURCE_PATH`: Host path to mount as source directory
- `DEST_PATH`: Host path to mount as destination directory

### Volume Mounts

The docker-compose file mounts:
- Source directory as read-only (`:ro`) to prevent accidental modifications
- Destination directory as read-write for storing converted files

## Script Options

The containerized script supports the same options as the original script:

- `--dry-run`: List files that would be converted without actually converting them
- `--jobs`: ⚠️  Deprecated - dnglab handles parallelization internally

## Examples

### Example 1: Basic Conversion

```bash
# Set up directories
export SOURCE_PATH="/mnt/photos/landing"
export DEST_PATH="/mnt/photos/converted"

# Run conversion
make convert
# or: podman-compose up cr3-to-dng-converter
```

### Example 2: Dry Run with Custom Paths

```bash
SOURCE_PATH="/home/user/DCIM" DEST_PATH="/home/user/DNG" make dry-run
# or: SOURCE_PATH="/home/user/DCIM" DEST_PATH="/home/user/DNG" \
#       podman-compose --profile dry-run up cr3-to-dng-converter-dry-run
```

### Example 3: One-time Conversion (Direct Podman)

```bash
podman run --rm \
  -v "/media/camera/DCIM:/photos/landing:ro,Z" \
  -v "/home/user/converted:/photos/converted:Z" \
  cr3-to-dng-converter
```

### Example 4: Using Make with Environment Variables

```bash
# Set environment variables
export SOURCE_PATH="/media/camera/DCIM"
export DEST_PATH="/home/user/converted"

# Use direct podman commands
make build-podman
make dry-run-podman
make convert-podman
```

## File Structure

```
.
├── Dockerfile                 # Docker image definition
├── docker-compose.yml        # Docker compose configuration
├── convert-cr3-to-dng.sh    # Conversion script
├── .dockerignore             # Docker build context exclusions
└── README.md                 # This file
```

## Troubleshooting

### Permission Issues with Podman

If you encounter permission issues with the converted files, Podman runs rootless by default, which is great for security. The `:Z` flag in volume mounts helps with SELinux contexts. If you still have permission issues:

1. **Check file ownership**: Files created in the container may have different ownership
2. **Use user namespaces**: Podman automatically maps container users to host users
3. **Fix permissions manually**: 
   ```bash
   sudo chown -R $(id -u):$(id -g) /path/to/converted/files
   ```

For rootless containers (default), the container runs as your user ID, so permissions should generally work correctly.

### Logs and Debugging

To see verbose output from the conversion process:

```bash
# With podman-compose
podman-compose run --rm cr3-to-dng-converter -v

# With direct podman
SOURCE_PATH="/path/to/cr3" DEST_PATH="/path/to/dng" make convert-podman
```

To check the container logs:

```bash
podman-compose logs cr3-to-dng-converter
```

### Container Cleanup

Remove stopped containers and images:

```bash
# With podman-compose
podman-compose down
podman system prune

# Direct podman cleanup
podman container prune
podman image prune
```

## Advanced Usage

### Using Pre-built Images from GitHub Actions

This repository automatically builds and publishes container images to GitHub Container Registry (GHCR) when code is pushed. You can use these pre-built images without building locally:

```bash
# Use the latest stable image
podman run --rm \
  -v "/path/to/cr3:/photos/landing:ro,Z" \
  -v "/path/to/converted:/photos/converted:Z" \
  ghcr.io/peterhenell/auto-convert-photos:latest

# Use a specific version (if tagged)
podman run --rm \
  -v "/path/to/cr3:/photos/landing:ro,Z" \
  -v "/path/to/converted:/photos/converted:Z" \
  ghcr.io/peterhenell/auto-convert-photos:v1.0.0

# Use with docker-compose by updating the image reference:
```

Update your `docker-compose.yml` to use the pre-built image:
```yaml
services:
  cr3-to-dng-converter:
    image: ghcr.io/peterhenell/auto-convert-photos:latest
    # Remove the 'build:' section when using pre-built images
```

### Custom dnglab Version

To use a different version of dnglab, modify the `DNGLAB_VERSION` build argument in the Dockerfile:

```dockerfile
ARG DNGLAB_VERSION=v0.7.0
```

### Persistent Container

If you want the container to stay running (e.g., for repeated conversions), modify the docker-compose.yml:

```yaml
restart: unless-stopped
command: ["tail", "-f", "/dev/null"]  # Keep container running
```

Then execute conversions manually:

```bash
docker-compose exec cr3-to-dng-converter /usr/local/bin/convert-cr3-to-dng.sh --dry-run
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project uses dnglab which is licensed under LGPL-2.1.