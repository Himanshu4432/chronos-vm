/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Guest-space test application invoking OP-TEE mediator capabilities.
 *
 * Copyright (C) 2026 Himanshu Kumar <himanshu@kvm-optee-bridge.org>
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdint.h>

#define TEE_IOC_MAGIC 0xa4
#define TEE_IOC_OPEN_SESSION   _IOWR(TEE_IOC_MAGIC, 2, struct tee_ioctl_open_session)
#define TEE_IOC_INVOKE         _IOWR(TEE_IOC_MAGIC, 3, struct tee_ioctl_invoke)

struct tee_ioctl_open_session {
	uint8_t uuid[16];
	uint32_t clnt_login;
	uint32_t cancel_id;
	uint32_t session;
	uint32_t err;
};

struct tee_ioctl_invoke {
	uint32_t session;
	uint32_t cmd;
	uint32_t cancel_id;
	uint32_t num_params;
	uint32_t err;
};

int main(void)
{
	int fd;
	struct tee_ioctl_open_session open_session_arg = {0};
	struct tee_ioctl_invoke invoke_arg = {0};

	printf("[Guest Test] Opening TEE device /dev/tee0...\n");
	fd = open("/dev/tee0", O_RDWR);
	if (fd < 0) {
		perror("Failed to open TEE device");
		return EXIT_FAILURE;
	}

	/* Target TEE UUID (Example: Secure Storage or Echo TA) */
	uint8_t target_uuid[16] = {
		0xbc, 0x50, 0xd9, 0x71, 0x83, 0xa1, 0x4f, 0x3d,
		0x8e, 0x79, 0x3b, 0x2c, 0x1f, 0x0a, 0x5e, 0xd2
	};
	for (int i = 0; i < 16; i++) {
		open_session_arg.uuid[i] = target_uuid[i];
	}

	printf("[Guest Test] Requesting session with Trusted Application via TEE Mediator...\n");
	if (ioctl(fd, TEE_IOC_OPEN_SESSION, &open_session_arg) < 0) {
		perror("ioctl TEE_IOC_OPEN_SESSION failed");
		close(fd);
		return EXIT_FAILURE;
	}
	printf("[Guest Test] Session opened successfully. Session ID: %u\n", open_session_arg.session);

	/* Invoke Command 1 (e.g. secure crypto echo) */
	invoke_arg.session = open_session_arg.session;
	invoke_arg.cmd = 1;
	invoke_arg.num_params = 0;

	printf("[Guest Test] Invoking Command 1 on TA...\n");
	if (ioctl(fd, TEE_IOC_INVOKE, &invoke_arg) < 0) {
		perror("ioctl TEE_IOC_INVOKE failed");
		close(fd);
		return EXIT_FAILURE;
	}

	printf("[Guest Test] TEE invocation succeeded through KVM OP-TEE mediator!\n");

	close(fd);
	return EXIT_SUCCESS;
}
