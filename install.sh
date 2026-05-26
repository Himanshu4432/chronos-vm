#!/bin/bash
# KVM OP-TEE Bridge Environment Setup Script
# Copyright (C) 2026 Himanshu Kumar <himanshu@kvm-optee-bridge.org>

set -e

echo "== Installing dependencies for ARM64 cross-compilation and QEMU =="
sudo apt-get update
sudo apt-get install -y \
    libgnutls28-dev \
    python3-venv \
    git \
    libglib2.0-dev \
    libfdt-dev \
    libpixman-1-dev \
    zlib1g-dev \
    ninja-build \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    bc \
    bison \
    flex \
    libssl-dev \
    make \
    qemu-system-arm

echo "== Initializing git submodules =="
git submodule update --init --recursive

echo "== System setup complete! Run 'make' to compile the environment. =="
