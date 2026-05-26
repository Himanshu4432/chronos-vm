#!/bin/sh
# Mount host-shared directory inside the guest VM
# Copyright (C) 2026 Himanshu Kumar <himanshu@kvm-optee-bridge.org>

SHARE_DIR="/mnt/shared"
mkdir -p "$SHARE_DIR"

echo "== Mounting guest-host shared folder via 9p =="
mount -t 9p -o trans=virtio,version=9p2000.L hostshare "$SHARE_DIR"

if [ $? -eq 0 ]; then
    echo "Successfully mounted shared folder to $SHARE_DIR"
else
    echo "Failed to mount shared folder. Make sure host sharing is enabled."
fi
