# Use Ubuntu as base image for better compatibility
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SRC_DIR=/photos/landing
ENV DST_DIR=/photos/converted

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    findutils \
    && rm -rf /var/lib/apt/lists/*

# Download and install dnglab
ARG DNGLAB_VERSION=v0.7.1
# Check the actual filename format in the releases
RUN curl -sL "https://api.github.com/repos/dnglab/dnglab/releases/tags/${DNGLAB_VERSION}" | \
    grep "browser_download_url.*linux_x64" | head -1 | cut -d '"' -f 4 | \
    xargs curl -L -o /usr/local/bin/dnglab && \
    chmod +x /usr/local/bin/dnglab && \
    /usr/local/bin/dnglab --version || echo "⚠️  dnglab download may have failed, trying alternative method" && \
    [ ! -s /usr/local/bin/dnglab ] && \
    curl -L "https://github.com/dnglab/dnglab/releases/download/${DNGLAB_VERSION}/dnglab-linux-x64_${DNGLAB_VERSION}" \
    -o /usr/local/bin/dnglab && chmod +x /usr/local/bin/dnglab || true

# Create directories for photos
RUN mkdir -p /photos/landing /photos/converted

# Copy the conversion script
COPY convert-cr3-to-dng.sh /usr/local/bin/convert-cr3-to-dng.sh
RUN chmod +x /usr/local/bin/convert-cr3-to-dng.sh

# Create a wrapper script that uses environment variables
RUN cat > /usr/local/bin/entrypoint.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Update the script with environment variables
sed -i "s|^SRC=.*|SRC=\"${SRC_DIR}\"|" /usr/local/bin/convert-cr3-to-dng.sh
sed -i "s|^DST=.*|DST=\"${DST_DIR}\"|" /usr/local/bin/convert-cr3-to-dng.sh

# Pass all arguments to the conversion script
exec /usr/local/bin/convert-cr3-to-dng.sh "$@"
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /photos

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be overridden)
CMD []