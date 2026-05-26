# Makefile for KVM OP-TEE Bridge KVM OP-TEE Mediator Simulation Stack
# Copyright (C) 2026 Himanshu Kumar <himanshu@kvm-optee-bridge.org>

DEBUG ?= 1
NPROC ?= $(shell nproc 2>/dev/null || echo 4)
ROOT  ?= $(shell pwd)
QEMU  ?= qemu-system-aarch64

.PHONY: all clean qemu u-boot optee linux tfa buildroot

all: buildroot u-boot linux tfa optee

# OP-TEE OS virtualized setup
OPTEE_FLAGS ?= CFG_ASLR=n \
               CROSS_COMPILE=aarch64-linux-gnu- \
               CROSS_COMPILE_core=aarch64-linux-gnu- \
               CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- \
               PLATFORM=vexpress-qemu_armv8a \
               O=out/arm/ \
               CFG_USER_TA_TARGETS=ta_arm64 \
               CFG_ARM64_core=y \
               CFG_TEE_CORE_LOG_LEVEL=3 \
               CFG_CORE_ASLR=n \
               CFG_ARM_GICV3=y \
               CFG_NS_VIRTUALIZATION=y \
               CFG_VIRT_GUEST_COUNT=2 \
               DEBUG=$(DEBUG)

optee:
	@echo "== Building OP-TEE OS with Virtualization Support =="
	cd optee_os && make $(OPTEE_FLAGS)

clean_optee:
	cd optee_os && make clean

# U-Boot bootloader
u-boot:
	@echo "== Building U-Boot for QEMU ARM64 =="
	cd u-boot && make qemu_arm64_defconfig && make -j$(NPROC)

clean_u-boot:
	cd u-boot && make clean

# ARM Trusted Firmware (TF-A) - Secure Monitor
TFA_FLAGS ?= CROSS_COMPILE=aarch64-linux-gnu- \
            PLAT=qemu \
            BL33=$(ROOT)/u-boot/u-boot.bin \
            DEBUG=$(DEBUG) \
            LOG_LEVEL=40 \
            ARM_LINUX_KERNEL_AS_BL33=0 \
            QEMU_USE_GIC_DRIVER=QEMU_GICV3 \
            BL32_RAM_LOCATION=tdram \
            BL32=$(ROOT)/optee_os/out/arm/core/tee-raw.bin \
            BL32_EXTRA1=$(ROOT)/optee_os/out/arm/core/tee-pager_v2.bin \
            BL32_EXTRA2=$(ROOT)/optee_os/out/arm/core/tee-pageable_v2.bin \
            SPD=opteed

tfa: optee u-boot
	@echo "== Building TF-A Bootloader =="
	cd arm-trusted-firmware && make $(TFA_FLAGS) -j$(NPROC)

clean_tfa:
	cd arm-trusted-firmware && make clean

# Linux Host Kernel with Mediator Patches
linux:
	@echo "== Applying Mediator Patches & Building Linux Kernel =="
	cd linux && \
	for p in $(ROOT)/patches/*.patch; do patch -p1 -N --dry-run < $$p >/dev/null 2>&1 && patch -p1 < $$p || echo "Patch $$p already applied"; done && \
	make defconfig && \
	make -j$(NPROC)

clean_linux:
	cd linux && make clean

# Buildroot for minimal VM Rootfs
buildroot:
	@echo "== Building Buildroot Rootfs =="
	cd buildroot && make qemu_arm64_defconfig && make -j$(NPROC)

clean_buildroot:
	cd buildroot && make clean

clean: clean_optee clean_u-boot clean_tfa clean_linux clean_buildroot

# Run simulation in QEMU
qemu: all
	@echo "== Starting QEMU with Secure and Non-Secure Worlds =="
	$(QEMU) \
		-bios $(ROOT)/arm-trusted-firmware/build/qemu/debug/bl1.bin \
		-machine virt,secure=on,gic-version=3 \
		-cpu max \
		-m 2048 \
		-semihosting-config enable=on,target=native \
		-netdev user,id=vnet \
		-device virtio-net-device,netdev=vnet \
		-nographic
