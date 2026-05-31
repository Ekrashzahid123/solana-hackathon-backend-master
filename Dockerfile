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

EXPOSE 3000

CMD ["/app/backend-rust"]
