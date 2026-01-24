FROM ubuntu:24.04
ARG BAZELISK_VERSION=v1.28.1

# Install essential packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    git \
    wget \
    curl \
    && true

# Install Bazelisk
RUN wget -q https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-amd64 -O /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

# Development tools
RUN apt-get install -y --no-install-recommends \
    tmux \
    mc \
    && true

# Clean up apt cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
