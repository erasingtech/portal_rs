# Use the official Rust nightly image as a parent image
FROM rustlang/rust:nightly-slim as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install cargo-leptos (latest version compatible with nightly)
RUN cargo install cargo-leptos

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

# Build the application
RUN cargo leptos build --release

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
