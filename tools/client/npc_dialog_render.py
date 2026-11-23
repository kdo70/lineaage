"""Native nine-slice adapter for the NPC dialog's static UI textures."""
from keystone import Ks, KS_ARCH_X86, KS_MODE_32

def assemble_render(address, cache_address, trampoline):
    # DrawTexture(x,y,w,h,u,v,uw,vh,texture,alpha,flags), thiscall.
    source = '''push ebp
mov ebp, esp
pushad
sub esp, 64
call anchor
anchor:
pop ebx
'''
    ks = Ks(KS_ARCH_X86, KS_MODE_32)
    anchor_offset = len(ks.asm(source, address)[0]) - 1
    source += f'add ebx, {cache_address-address-anchor_offset}\n'
    source += '''mov ecx, 2
next_root:
mov eax, [ebx]
test eax, eax
jz advance
'''
    serial = 0
    def compare(reg):
        nonlocal serial
        serial += 1
        return f'test {reg}, {reg}\njz skip_{serial}\n' + ''.join(f'cmp {reg}, [ebp-{offset}]\nje eligible\n' for offset in (16,28,32)) + f'skip_{serial}:\n'
    source += compare('eax')
    source += 'mov edx, [eax+0xc0]\n'+compare('edx')
    source += 'mov eax, [eax+0x1cc]\n'+compare('eax')
    for offset in (0xc0,0x1ec,0x1f0,0x1f4,0x1f8,0x1fc,0x200):
        source += f'mov edx, [eax+{offset}]\n'+compare('edx')
    source += '''advance:
add ebx, 20
loop next_root
jmp original
eligible:
cmp dword ptr [ebp+24], 0
jne original
cmp dword ptr [ebp+28], 0
jne original
mov eax, [ebp+40]
test eax, eax
jz original
mov edx, [eax+0x580]
mov ecx, [eax+0x584]
mov eax, [ebx]
cmp eax, [ebp-28]
jne not_outer
fld dword ptr [ebx+4]
fistp dword ptr [ebp-36]
fld dword ptr [ebx+8]
fistp dword ptr [ebp-40]
sub dword ptr [ebp-40], 20
jmp logical_bounds
not_outer:
mov eax, [eax+0xc0]
cmp eax, [ebp-28]
jne not_header
fld dword ptr [ebx+4]
fistp dword ptr [ebp-36]
mov dword ptr [ebp-40], 20
jmp logical_bounds
not_header:
fld dword ptr [ebx+12]
fistp dword ptr [ebp-36]
fld dword ptr [ebx+16]
fistp dword ptr [ebp-40]
logical_bounds:
cmp edx, [ebp-36]
jle logical_width_ready
mov edx, [ebp-36]
logical_width_ready:
cmp ecx, [ebp-40]
jle logical_height_ready
mov ecx, [ebp-40]
logical_height_ready:
cmp edx, 1
jle original
cmp ecx, 1
jle original
cmp edx, 4096
ja original
cmp ecx, 4096
ja original
cmp [ebp+32], edx
jg adapt
cmp [ebp+36], ecx
jle original
adapt:
cmp [ebp+32], edx
jge width_ready
mov edx, [ebp+32]
width_ready:
cmp [ebp+36], ecx
jge height_ready
mov ecx, [ebp+36]
height_ready:
cmp edx, 1
jle original
cmp ecx, 1
jle original
cmp dword ptr [ebp+16], 0
jle original
cmp dword ptr [ebp+20], 0
jle original
'''
    # Four cuts on each axis. Border cannot exceed half of either rectangle.
    for axis, texreg, dstarg, base in [('x','edx',16,36),('y','ecx',20,68)]:
        source += f'''mov eax, {texreg}
shr eax, 1
cmp eax, 8
jbe border_{axis}
mov eax, 8
border_{axis}:
mov ebx, [ebp+{dstarg}]
shr ebx, 1
cmp eax, ebx
jbe ready_{axis}
mov eax, ebx
ready_{axis}:
mov dword ptr [ebp-{base}], 0
mov [ebp-{base+4}], eax
mov ebx, {texreg}
sub ebx, eax
mov [ebp-{base+8}], ebx
mov [ebp-{base+12}], {texreg}
mov dword ptr [ebp-{base+16}], 0
mov [ebp-{base+20}], eax
mov ebx, [ebp+{dstarg}]
sub ebx, eax
mov [ebp-{base+24}], ebx
mov ebx, [ebp+{dstarg}]
mov [ebp-{base+28}], ebx
'''
    for y in range(3):
        for x in range(3):
            source += 'push [ebp+48]\npush [ebp+44]\npush [ebp+40]\n'
            for base, i in [(68,y),(36,x)]:
                source += f'mov eax, [ebp-{base+(i+1)*4}]\nsub eax, [ebp-{base+i*4}]\npush eax\n'
            source += f'push [ebp-{68+y*4}]\npush [ebp-{36+x*4}]\n'
            for base, i in [(68,y),(36,x)]:
                source += f'mov eax, [ebp-{base+16+(i+1)*4}]\nsub eax, [ebp-{base+16+i*4}]\npush eax\n'
            for base,i,arg in [(68,y,12),(36,x,8)]:
                source += f'mov eax, [ebp-{base+16+i*4}]\nadd eax, [ebp+{arg}]\npush eax\n'
            source += f'mov ecx, [ebp-8]\ncall {trampoline}\n'
    source += f'''add esp, 64
popad
pop ebp
ret 44
original:
add esp, 64
popad
pop ebp
jmp {trampoline}
'''
    # Keystone's LOOP only accepts short targets; the tree matcher is longer.
    source = source.replace('loop next_root','dec ecx\njnz next_root')
    return bytes(ks.asm(source,address)[0])
