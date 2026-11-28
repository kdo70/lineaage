"""Smoke-test the activity hooks at a relocated image address without starting the client."""

import struct
import sys
from pathlib import Path

from patch_server_list_activity import patch, pefile
from unicorn import UC_ARCH_X86, UC_HOOK_CODE, UC_MODE_32, Uc
from unicorn.x86_const import UC_X86_REG_EAX, UC_X86_REG_EBP, UC_X86_REG_ECX, UC_X86_REG_EDI, UC_X86_REG_ESI, UC_X86_REG_ESP


def verify(path):
    pe = pefile.PE(data=bytes(patch(path.read_bytes())))
    base = 0x18000000
    stack = 0x20008000
    uc = Uc(UC_ARCH_X86, UC_MODE_32)
    uc.mem_map(base, pe.OPTIONAL_HEADER.SizeOfImage)
    uc.mem_write(base, pe.get_memory_mapped_image())
    uc.mem_map(0x20000000, 0x10000)
    uc.mem_map(0x21000000, 0x1000)
    formatter = 0x21000000
    button = formatter + 0x100

    def set_word(address, value):
        uc.mem_write(address, struct.pack("<I", value))

    def get_word(address):
        return struct.unpack("<I", uc.mem_read(address, 4))[0]

    def run(start, end):
        uc.reg_write(UC_X86_REG_ESP, stack)
        uc.emu_start(base + start, base + end, count=100)
        return uc.reg_read(UC_X86_REG_ESP)

    assert get_word(base + 0x1AA3C4) == 108
    assert run(0x1AA435, 0x1AA473) == stack
    assert run(0x180970, 0x1809F9) == stack
    assert get_word(base + 0x180928) == 542
    assert get_word(base + 0x1AA2AC) == 486
    assert get_word(base + 0x1AA32E) == 0
    assert get_word(base + 0x1AA340) == 0xffffffff
    run(0x1AA369, 0x1AA373)
    assert uc.reg_read(UC_X86_REG_EDI) == 143
    assert uc.mem_read(base + 0x1AA293, 1) == bytes([27])
    assert run(0x1AA6F8, 0x1AA82E) == stack
    for button_y in (0x1AA58A, 0x1AA6C1, 0x1AA7FA):
        assert get_word(base + button_y) == 509

    rectangles = []
    def capture_texture(emu, address, size, data):
        args = emu.reg_read(UC_X86_REG_ESP) + 4
        rectangles.append(struct.unpack("<11I", emu.mem_read(args, 44)))
    uc.mem_write(base + 0x21A00, b"\xc2\x2c\x00")
    handle = uc.hook_add(UC_HOOK_CODE, capture_texture, begin=base + 0x21A00, end=base + 0x21A00)
    uc.mem_write(stack, struct.pack("<11I", 0, 0, 316, 542, 0, 0, 316, 542, 1, 255, 1))
    assert run(0x1A8BF6, 0x1A8BFB) == stack + 44
    uc.hook_del(handle)
    assert [(r[1], r[3], r[5], r[7]) for r in rectangles] == [
        (0, 282, 0, 282), (282, 212, 44, 212), (494, 48, 282, 48)
    ]

    # The real cdecl formatter is in Core.dll. Capture its three arguments.
    uc.mem_write(formatter, b"\x8b\x44\x24\x04\x8b\x4c\x24\x0c\x89\x08\xc3")
    set_word(base + 0x22C450, formatter)
    set_word(button + 0x308, 452)
    for flag, count, title in ((0x100, 0, "Онлайн"), (0x200, 2345, "Онлайн за 24ч"), (0x200, 0x1fffff, "Онлайн за 24ч")):
        set_word(stack + 0x14, 1)
        set_word(stack + 0x18, flag | (count << 10) | 2)
        assert run(0x1A9B9A, 0x1A9CD0) == stack - 4
        assert get_word(stack + 0x38) == count

        encoded = (title + "\0").encode("utf-16le")
        for hook, end, esi, caption_offset in ((0x3553B, 0x35540, button, 4), (0x355BD, 0x355C3, 452, 4)):
            uc.reg_write(UC_X86_REG_ESI, esi)
            uc.reg_write(UC_X86_REG_EBP, stack + 0x100)
            new_stack = run(hook, end)
            assert bytes(uc.mem_read(get_word(new_stack + caption_offset), len(encoded))) == encoded

    set_word(stack + 0x14, 0)
    set_word(stack + 0x18, 0x200)
    assert run(0x1A9B9A, 0x1A9BA0) == stack
    assert uc.reg_read(UC_X86_REG_EAX) == 0

    uc.reg_write(UC_X86_REG_ECX, button)
    set_word(stack + 4, 9)
    run(0x1A84D0, 0x1A84DA)
    assert get_word(button + 0x1E0) == 9
    uc.reg_write(UC_X86_REG_EAX, formatter)
    uc.reg_write(UC_X86_REG_ESI, 452)
    new_stack = run(0x355BD, 0x355C3)
    assert get_word(new_stack + 4) == formatter


if __name__ == "__main__":
    for filename in sys.argv[1:]:
        verify(Path(filename))
        print(f"Passed {filename}")
