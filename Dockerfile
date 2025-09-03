# Use newer Rust version that properly supports edition2024
FROM rust:1.83-slim as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    perl \
    make \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables to use system OpenSSL
ENV OPENSSL_NO_VENDOR=1
ENV PKG_CONFIG_ALLOW_CROSS=1

# Set the working directory
WORKDIR /app

# Copy the Cargo files
COPY Cargo.toml rust-toolchain.toml ./
# Copy Cargo.lock if it exists (for reproducible builds)
COPY Cargo.lock* ./

# Copy the source code
COPY src ./src
COPY style ./style
COPY assets ./assets

# Create output directories
RUN mkdir -p target/site

# Build the SSR server binary only (no client-side hydration)
RUN cargo build --release --bin leptos_ssr_actix --features ssr --no-default-features

# Copy static assets to site directory
RUN cp -r assets/* target/site/ 2>/dev/null || true
RUN cp -r style/* target/site/ 2>/dev/null || true

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the built application
COPY --from=builder /app/target/release/leptos_ssr_actix /app/
COPY --from=builder /app/target/site /app/target/site

# Set environment variables
ENV LEPTOS_SITE_ADDR="0.0.0.0:$PORT"
ENV LEPTOS_SITE_ROOT="target/site"
ENV RUST_LOG="info"

# Expose the port
EXPOSE $PORT

# Run the application
CMD ["./leptos_ssr_actix"]
