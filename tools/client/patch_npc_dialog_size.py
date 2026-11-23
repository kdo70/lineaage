"""Build a version-checked, position-independent NPC dialog sizing patch."""
import argparse
import hashlib
import struct
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'python'))
import pefile
from keystone import Ks, KS_ARCH_X86, KS_MODE_32

EXPECTED = '2ad19421ad55c3a24ad481eb511dd0d0331ad3fd0bb82bedce178bfd0b37313a'

def assemble(address):
    # Two native NPC viewers: cache their original outer and inner dimensions.
    source = '''
        pushad
        mov esi, ecx
        mov edi, eax
        call anchor
    anchor:
        pop ebx
        add ebx, 2048 - 11
        cmp [ebx], esi
        je cached
        cmp dword ptr [ebx], 0
        je remember
        add ebx, 20
        cmp [ebx], esi
        je cached
        cmp dword ptr [ebx], 0
        jne done
    remember:
        mov [ebx], esi
        mov eax, [esi+0x88]
        mov [ebx+4], eax
        mov eax, [esi+0x8c]
        mov [ebx+8], eax
        mov ecx, [esi+0x1cc]
        mov eax, [ecx+0x88]
        mov [ebx+12], eax
        mov eax, [ecx+0x8c]
        mov [ebx+16], eax
    cached:
        sub esp, 16
        mov eax, [ebx+4]
        mov [esp], eax
        mov eax, [ebx+8]
        mov [esp+4], eax
        mov eax, [ebx+12]
        mov [esp+8], eax
        mov eax, [ebx+16]
        mov [esp+12], eax
    '''
    for i, c in enumerate('<!--L2SIZE:'):
        source += f'cmp word ptr [edi+{i*2}], {ord(c)}\njne resize\n'
    source += '''
        xor edx, edx
        mov ecx, 8
        lea ebp, [edi+22]
    digit:
        movzx eax, word ptr [ebp]
        sub eax, 48
        cmp eax, 9
        jbe number
        sub eax, 7
        cmp eax, 10
        jb resize
        cmp eax, 15
        ja resize
    number:
        shl edx, 4
        or edx, eax
        add ebp, 2
        loop digit
        cmp word ptr [ebp], 45
        jne resize
        cmp word ptr [ebp+2], 45
        jne resize
        cmp word ptr [ebp+4], 62
        jne resize
        mov eax, edx
        shr eax, 16
        and edx, 65535
        cmp eax, 200
        jb resize
        cmp eax, 1920
        ja resize
        cmp edx, 120
        jb resize
        cmp edx, 1080
        ja resize
        mov [esp], eax
        fild dword ptr [esp]
        fstp dword ptr [esp]
        mov [esp+4], edx
        fild dword ptr [esp+4]
        fstp dword ptr [esp+4]
        sub eax, 14
        sub edx, 37
        mov [esp+8], eax
        fild dword ptr [esp+8]
        fstp dword ptr [esp+8]
        mov [esp+12], edx
        fild dword ptr [esp+12]
        fstp dword ptr [esp+12]
    resize:
        push [esp+4]
        push [esp+4]
        mov ecx, esi
        mov eax, [ecx]
        call dword ptr [eax+0x128]
        mov ecx, [esi+0xc0]
        test ecx, ecx
        jz no_header
        push 0x41a00000
        push [esp+4]
        mov eax, [ecx]
        call dword ptr [eax+0x128]
    no_header:
        push [esp+12]
        push [esp+12]
        mov ecx, [esi+0x1cc]
        mov eax, [ecx]
        call dword ptr [eax+0x128]
        add esp, 16
    done:
        popad
        push eax
        mov ecx, [ecx+0x1cc]
    '''
    ks = Ks(KS_ARCH_X86, KS_MODE_32)
    prefix = bytes(ks.asm(source, address)[0])
    # The anchor return address is seven bytes from the start (pushad/mov/mov/call).
    anchor = prefix.index(b'\xe8\x00\x00\x00\x00') + 5
    prefix = prefix.replace(struct.pack('<I', 2048-11), struct.pack('<I', 2048-anchor), 1)
    tail = bytes(ks.asm(f'call {0x10088440}; jmp {0x10088e8b}', address+len(prefix))[0])
    return (prefix+tail).ljust(2048, b'\x90') + bytes(40)

def patch(data):
    if hashlib.sha256(data).hexdigest() != EXPECTED:
        raise ValueError('Unsupported nwindow.dll; refusing to patch')
    pe = pefile.PE(data=data)
    align = lambda n, a: (n+a-1)//a*a
    last = pe.sections[-1]
    rva = align(last.VirtualAddress+last.Misc_VirtualSize, pe.OPTIONAL_HEADER.SectionAlignment)
    raw = align(len(data), pe.OPTIONAL_HEADER.FileAlignment)
    payload = assemble(pe.OPTIONAL_HEADER.ImageBase+rva)
    from npc_dialog_render import assemble_render
    render_offset = 4096
    trampoline_offset = 8192
    base = pe.OPTIONAL_HEADER.ImageBase+rva
    render = assemble_render(base+render_offset, base+2048, base+trampoline_offset)
    if len(render) >= trampoline_offset-render_offset:
        raise ValueError('Render adapter exceeds reserved code area')
    ks = Ks(KS_ARCH_X86, KS_MODE_32)
    trampoline = data[pe.get_offset_from_rva(0x21a00):pe.get_offset_from_rva(0x21a00)+5]
    trampoline += bytes(ks.asm('jmp 0x10021a05',base+trampoline_offset+5)[0])
    payload = payload.ljust(render_offset,b'\x90') + render
    payload = payload.ljust(trampoline_offset,b'\x90') + trampoline
    size = align(len(payload), pe.OPTIONAL_HEADER.FileAlignment)
    header = pe.sections[-1].get_file_offset()+40
    if header+40 > pe.OPTIONAL_HEADER.SizeOfHeaders or any(data[header:header+40]):
        raise ValueError('No room for section header')
    out = bytearray(data.ljust(raw, b'\0'))
    out.extend(payload.ljust(size, b'\0'))
    out[header:header+40] = struct.pack('<8sIIIIIIHHI', b'.l2size',len(payload),rva,size,raw,0,0,0,0,0xE0000060)
    struct.pack_into('<H',out,pe.FILE_HEADER.get_field_absolute_offset('NumberOfSections'),len(pe.sections)+1)
    struct.pack_into('<I',out,pe.OPTIONAL_HEADER.get_field_absolute_offset('SizeOfImage'),align(rva+len(payload),pe.OPTIONAL_HEADER.SectionAlignment))
    hook = pe.get_offset_from_rva(0x88e7f)
    out[hook:hook+12] = b'\xe9'+struct.pack('<i',rva-0x88e7f-5)+b'\x90'*7
    draw_hook = pe.get_offset_from_rva(0x21a00)
    out[draw_hook:draw_hook+5] = b'\xe9'+struct.pack('<i',rva+render_offset-0x21a00-5)
    return bytes(out)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        raise SystemExit('Use a separate output file')
    args.output.write_bytes(patch(args.input.read_bytes()))
    print(args.output)
