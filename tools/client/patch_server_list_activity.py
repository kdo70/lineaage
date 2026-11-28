"""Patch the High Five server-list labels for the activity flags sent by LoginServer."""

import argparse
import hashlib
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python"))
import pefile
from keystone import KS_ARCH_X86, KS_MODE_32, Ks

EXPECTED = {
    "8d95236efaa01e279168c3d2ca6811e175326640e175fa8e99c0e00fb021cb1d",
    "a991efe2f3f5e84458c6de601dc2a360e7235602e34e281d6da5b6423d8ced7a",
}


def patch(data):
    if hashlib.sha256(data).hexdigest() not in EXPECTED:
        raise ValueError("Unsupported nwindow.dll")
    pe = pefile.PE(data=data)
    image_base = pe.OPTIONAL_HEADER.ImageBase

    def align(value, alignment):
        return (value + alignment - 1) // alignment * alignment

    last = pe.sections[-1]
    section_alignment = pe.OPTIONAL_HEADER.SectionAlignment
    file_alignment = pe.OPTIONAL_HEADER.FileAlignment
    rva = align(last.VirtualAddress + last.Misc_VirtualSize, section_alignment)
    mode_rva = rva + 0x400
    online_rva = mode_rva + 4
    daily_rva = mode_rva + 0x20
    raw = align(len(data), file_alignment)
    assembler = Ks(KS_ARCH_X86, KS_MODE_32)
    payload = bytearray(0x540)
    output = bytearray(data.ljust(raw, b"\0"))

    def install(hook, original, offset, body):
        address = image_base + rva + offset
        body = body.replace("MODULE_BASE", f"call anchor\nanchor:\npop edx\nsub edx, {rva + offset + 5}")
        code = bytes(assembler.asm(body, address)[0])
        assert len(code) <= 0x100
        payload[offset:offset + len(code)] = code
        original = bytes.fromhex(original)
        position = pe.get_offset_from_rva(hook)
        if output[position:position + len(original)] != original:
            raise ValueError(f"Unexpected code at RVA {hook:#x}")
        jump = bytes(assembler.asm(f"jmp {address}", image_base + hook)[0])
        output[position:position + len(original)] = jump.ljust(len(original), b"\x90")

    # Reset the mode when the client starts receiving a fresh server list.
    install(0x1A84D0, "8b4424048981e0010000", 0, f"""
        MODULE_BASE
        mov dword ptr [edx + {mode_rva}], 0
        mov eax, [esp + 4]
        mov [ecx + 0x1e0], eax
        jmp {image_base + 0x1A84DA}
    """)

    # Choose the header even for a down server, but preserve its original row text.
    # The numeric branch rejoins before ping handling, leaving metadata and sorting intact.
    install(0x1A9B9A, "8b44241485c0", 0x100, f"""
        MODULE_BASE
        mov eax, [esp + 0x18]
        mov ecx, eax
        and ecx, 0x300
        jz stock
        mov [edx + {mode_rva}], ecx
        cmp dword ptr [esp + 0x14], 1
        jne stock
        shr eax, 10
        push eax
        lea ecx, [edx + 0x233718]
        push ecx
        lea eax, [esp + 0x40]
        push eax
        mov edi, [edx + 0x22c450]
        call edi
        add esp, 12
        push 0xff64a3d9
        jmp {image_base + 0x1A9CD0}
    stock:
        mov eax, [esp + 0x14]
        test eax, eax
        jmp {image_base + 0x1A9BA0}
    """)

    # Column caption 452 is measured and painted via separate lookups.
    for hook, original, offset, caption_id, instructions in (
        (0x3553B, "508d4dd051", 0x200, "dword ptr [esi + 0x308]", "push eax\nlea ecx, [ebp - 0x30]\npush ecx"),
        (0x355BD, "5068bedce6ff", 0x300, "esi", "push eax\npush 0xffe6dcbe"),
    ):
        install(hook, original, offset, f"""
            MODULE_BASE
            cmp {caption_id}, 452
            jne use_caption
            mov ecx, [edx + {mode_rva}]
            cmp ecx, 0x100
            jne check_daily
            lea eax, [edx + {online_rva}]
            jmp use_caption
        check_daily:
            cmp ecx, 0x200
            jne use_caption
            lea eax, [edx + {daily_rva}]
        use_caption:
            {instructions}
            jmp {image_base + hook + len(bytes.fromhex(original))}
        """)

    # Give the activity column the width previously used by the fifth column (Type).
    width = pe.get_offset_from_rva(0x1AA3C4)
    if output[width:width + 4] != struct.pack("<I", 59):
        raise ValueError("Unexpected stock activity column width")
    struct.pack_into("<I", output, width, 59 + 49)

    type_column = pe.get_offset_from_rva(0x1AA435)
    if output[type_column:type_column + 7] != bytes.fromhex("8d8c2494000100"):
        raise ValueError("Unexpected Type column setup")
    jump = bytes(assembler.asm(f"jmp {image_base + 0x1AA473}", image_base + 0x1AA435)[0])
    output[type_column:type_column + 7] = jump.ljust(7, b"\x90")

    # Skip constructing and attaching the lower server-help window.
    help_window = pe.get_offset_from_rva(0x180970)
    original = bytes.fromhex("6a00518bcc8965e8")
    if output[help_window:help_window + len(original)] != original:
        raise ValueError("Unexpected server-help window setup")
    code = bytes(assembler.asm(f"xor eax, eax; jmp {image_base + 0x1809F9}", image_base + 0x180970)[0])
    output[help_window:help_window + len(original)] = code.ljust(len(original), b"\x90")

    # Extend the server list and its frame to the former help panel's bottom.
    extra_height = 0x151 + 0xCD - 0x14A
    for instruction, original_value in (
        (0x180927, 0x14A),  # Frame height.
        (0x1AA2AB, 0x112),  # List height, including its scroll bar.
        (0x1AA589, 0x129),  # Accept button.
        (0x1AA6C0, 0x129),  # Cancel button.
        (0x1AA7F9, 0x129),  # Quality button.
    ):
        position = pe.get_offset_from_rva(instruction)
        if output[position:position + 5] != b"\x68" + struct.pack("<I", original_value):
            raise ValueError(f"Unexpected window geometry at RVA {instruction:#x}")
        struct.pack_into("<I", output, position + 1, original_value + extra_height)

    # The background texture still has the old height. Draw the original
    # upper and lower edges and fill the new space with a strip of list rows.
    draw_texture = image_base + 0x21A00
    draw_background = "push ebp; mov ebp, esp; push esi; mov esi, ecx\n"
    for y, source_y, height in ((0, 0, 282), (282, 44, extra_height), (282 + extra_height, 282, 48)):
        draw_background += f"""
            push [ebp + 48]
            push [ebp + 44]
            push [ebp + 40]
            push {height}
            push [ebp + 32]
            push {source_y}
            push [ebp + 24]
            push {height}
            push [ebp + 16]
            push {y}
            push [ebp + 8]
            mov ecx, esi
            call {draw_texture}
        """
    draw_background += f"pop esi; pop ebp; add esp, 44; jmp {image_base + 0x1A8BFB}"
    install(0x1A8BF6, "e8058eE7ff", 0x440, draw_background.replace(
        "push ebp; mov ebp, esp;", "push ebp; lea ebp, [esp - 4];"
    ))

    # Keep the ID column's internal slot for the native row and sort handlers.
    # Give it no display width or caption and reclaim its width for the name.
    for address, old, new in (
        (0x1AA32E, 32, 0),
        (0x1AA340, 416, 0xFFFFFFFF),
        (0x1AA293, 15, 27),  # Visible rows, with a 17-pixel row height.
        (0x1AA58F, 121, 80), # Accept x-coordinate.
        (0x1AA6C6, 201, 160), # Cancel x-coordinate.
    ):
        size = 4 if address in (0x1AA32E, 0x1AA340, 0x1AA6C6) else 1
        position = pe.get_offset_from_rva(address)
        if output[position:position + size] != old.to_bytes(size, "little"):
            raise ValueError(f"Unexpected table layout at RVA {address:#x}")
        output[position:position + size] = new.to_bytes(size, "little")

    # The original ADD uses a signed byte immediate, which cannot hold 143.
    name_width = pe.get_offset_from_rva(0x1AA369)
    original = bytes.fromhex("f7df1bff83e72083c76f")
    if output[name_width:name_width + len(original)] != original:
        raise ValueError("Unexpected name column width calculation")
    code = bytes(assembler.asm("mov edi, 143")[0])
    output[name_width:name_width + len(original)] = code.ljust(len(original), b"\x90")

    quality = pe.get_offset_from_rva(0x1AA6F8)
    original = pe.get_data(0x1AA6F8, 6)
    if original[:2] != b"\x6a\x00":
        raise ValueError("Unexpected quality button setup")
    code = bytes(assembler.asm(f"xor ebp, ebp; jmp {image_base + 0x1AA82E}", image_base + 0x1AA6F8)[0])
    output[quality:quality + len(code)] = code

    for address, title in ((online_rva, "Онлайн"), (daily_rva, "Онлайн за 24ч")):
        encoded = (title + "\0").encode("utf-16le")
        start = address - rva
        payload[start:start + len(encoded)] = encoded

    header = last.get_file_offset() + 40
    if header + 40 > pe.OPTIONAL_HEADER.SizeOfHeaders or any(data[header:header + 40]):
        raise ValueError("No space for a new section header")
    raw_size = align(len(payload), file_alignment)
    output.extend(payload.ljust(raw_size, b"\0"))
    output[header:header + 40] = struct.pack(
        "<8sIIIIIIHHI", b".l2act", len(payload), rva, raw_size, raw, 0, 0, 0, 0, 0xE0000060
    )
    struct.pack_into("<H", output, pe.FILE_HEADER.get_field_absolute_offset("NumberOfSections"), len(pe.sections) + 1)
    struct.pack_into("<I", output, pe.OPTIONAL_HEADER.get_field_absolute_offset("SizeOfImage"), align(rva + len(payload), section_alignment))
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        parser.error("Use a separate output file")
    args.output.write_bytes(patch(args.source.read_bytes()))
