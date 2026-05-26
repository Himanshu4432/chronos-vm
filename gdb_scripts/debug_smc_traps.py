# GDB Python script to debug KVM EL2 SMC traps
# Copyright (C) 2026 Himanshu Kumar <himanshu@kvm-optee-bridge.org>

import gdb

class SMCBreakpoint(gdb.Breakpoint):
    def __init__(self):
        super(SMCBreakpoint, self).__init__("handle_smc")
        print("SMC Breakpoint registered on handle_smc")

    def stop(self):
        # Retrieve vcpu pointer
        vcpu = gdb.selected_frame().read_var("vcpu")
        # Extract guest registers from vcpu state
        regs = vcpu['arch']['ctxt']['regs']
        a0 = regs['regs'][0]
        a1 = regs['regs'][1]
        a2 = regs['regs'][2]
        a3 = regs['regs'][3]
        print("[GDB SMC Trap] Guest executed SMC. a0: {:#x}, a1: {:#x}, a2: {:#x}, a3: {:#x}".format(
            long(a0), long(a1), long(a2), long(a3)
        ))
        # Continue execution automatically
        return False

# Initialize breakpoint
SMCBreakpoint()
