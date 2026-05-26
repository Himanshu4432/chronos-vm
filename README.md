# KVM OP-TEE Bridge: KVM OP-TEE Mediator

KVM OP-TEE Bridge introduces a high-performance **KVM OP-TEE Mediator** for ARM64 virtualized environments. It bridges the gap between non-secure guest VMs and the OP-TEE Trusted Execution Environment (TEE) operating in the Secure World (ARM TrustZone).

## The Problem

On ARM64, TEE access is triggered using the Secure Monitor Call (`SMC`) instruction. In virtualized systems:
1. Guest `SMC` instructions are automatically trapped at Exception Level 2 (`EL2`) by the host hypervisor (KVM).
2. KVM historically ignores or drops these guest SMCs.
3. Guests are cut off from secure hardware features like key storage, cryptographic accelerators, and Trusted Applications (TAs).

## Architecture & How It Works

```
 +-----------------------------------------------------------------+
 |                           NORMAL WORLD                          |
 |                                                                 |
 |  +--------------------+                   +-------------------+ |
 |  |    Guest VM (EL1)  |                   |   Host OS (EL1)   | |
 |  |  +--------------+  |                   |  +-------------+  | |
 |  |  | User App     |  |                   |  | TEE Driver  |  | |
 |  |  +-------+------+  |                   |  +-------------+  | |
 |  |          | ioctl   |                   |                   | |
 |  |  +-------v------+  |                   |  +-------------+  | |
 |  |  | TEE Client   |  |                   |  | OP-TEE Med. |  | |
 |  |  +-------+------+  |                   |  +------+------+  | |
 |  |          | SMC     |                   |         ^         | |
 |  +----------|---------+                   +---------|---------+ |
 |             |                                       |           |
 |             +=========> [ KVM Trap (EL2) ] =========+           |
 |                              handle_exit.c                      |
 +-------------------------------------+---------------------------+
                                       | SMC
 ======================================|============================
                                       v
 +-----------------------------------------------------------------+
 |                           SECURE WORLD                          |
 |                                                                 |
 |                     [ Secure Monitor (EL3) ]                    |
 |                                                                 |
 |                      +--------------------+                     |
 |                      |     OP-TEE OS      |                     |
 |                      +--------------------+                     |
 +-----------------------------------------------------------------+
```

### Key Components
- **SMC Interception & Forwarding:** Trap guest SMCs in KVM EL2, forward the vCPU registers to the mediator, and context switch to the secure monitor.
- **Address Translation (IPA to PA):** Guests use Intermediate Physical Addresses (IPAs). The mediator dynamically translates guest buffer pointers to physical memory (PA) before forwarding to OP-TEE.
- **VM Lifecycle Management:** Informs OP-TEE on guest VM creation/destruction (`OPTEE_SMC_VM_CREATED` and `OPTEE_SMC_VM_DESTROYED`) to maintain multi-tenant isolation.
- **Memory Pinning:** Ensures guest-shared memory structures remain pinned in host RAM during active TEE calls.
