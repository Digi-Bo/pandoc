# Use Haskell as base image since pandoc is written in Haskell
FROM haskell:9.4 as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    zlib1g-dev \
    libgmp-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone pandoc repository
WORKDIR /opt
RUN git clone https://github.com/jgm/pandoc.git
WORKDIR /opt/pandoc

# Install stack
RUN curl -sSL https://get.haskellstack.org/ | sh

# Build pandoc with server support
RUN stack setup
RUN stack install pandoc-cli --flag pandoc-cli:server

# Create symbolic link for pandoc-server
RUN ln -s /root/.local/bin/pandoc /root/.local/bin/pandoc-server

# Final stage with minimal runtime dependencies
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libgmp10 \
    zlib1g \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the built binary and symbolic link from builder
COPY --from=builder /root/.local/bin/pandoc /usr/local/bin/pandoc
COPY --from=builder /root/.local/bin/pandoc-server /usr/local/bin/pandoc-server

# Create directory for temporary files
RUN mkdir -p /tmp/pandoc

# Expose the default port
EXPOSE 3030

# Set environment variables
ENV PANDOC_SERVER_TIMEOUT=30

# Start pandoc-server
CMD ["pandoc-server", "--port", "3030"]
