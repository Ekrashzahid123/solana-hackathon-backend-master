FROM rust:1.76-bullseye AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libssl-dev \
    libpq-dev \
    clang \
    llvm \
    libudev-dev \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock ./
# Copy local .env into the image so dotenvy can load environment variables
# during development/testing. For production (Railway) prefer setting env vars
# via the platform instead of baking secrets into the image.
COPY .env ./
RUN cargo fetch

COPY src ./src
COPY migrations ./migrations

RUN cargo build --release --bin backend-rust
RUN strip target/release/backend-rust || true

FROM debian:bookworm-slim AS runtime

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/backend-rust /app/backend-rust
COPY --from=builder /app/migrations /app/migrations
# Also copy .env into the runtime image so dotenvy can load it at runtime
COPY .env ./

EXPOSE 3000

CMD ["/app/backend-rust"]
