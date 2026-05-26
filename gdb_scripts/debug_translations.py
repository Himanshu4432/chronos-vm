# GDB Python script to inspect Guest IPA to Host PA translations
# Copyright (C) 2026 Himanshu Kumar <himanshu@kvm-optee-bridge.org>

import gdb

class TranslateIPABreakpoint(gdb.Breakpoint):
    def __init__(self):
        super(TranslateIPABreakpoint, self).__init__("translate_and_pin_ipa")
        print("Translation breakpoint registered on translate_and_pin_ipa")

    def stop(self):
        ipa = gdb.selected_frame().read_var("ipa")
        print("[GDB Memory Translation] Intercepted IPA translation for guest buffer. Guest IPA: {:#x}".format(
            long(ipa)
        ))
        
        # Run step to see translated PFN
        gdb.execute("next")
        pfn = gdb.selected_frame().read_var("pfn")
        pa = (long(pfn) << 12) | (long(ipa) & 0xfff)
        print("[GDB Memory Translation] Resolved to Host PA: {:#x}".format(pa))
        return False

TranslateIPABreakpoint()
