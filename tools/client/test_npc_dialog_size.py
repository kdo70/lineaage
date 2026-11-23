"""Execute the actual x86 sizing hook with mocked native resize/load methods."""
import sys
import struct
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'python'))
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *
from patch_npc_dialog_size import patch
import pefile

uc = Uc(UC_ARCH_X86, UC_MODE_32)
for address, size in [(0x10000000,0x1000000),(0x200000,0x10000),(0x300000,0x10000)]:
    uc.mem_map(address,size)
import os
original = Path(os.environ.get("LINEAGE_NWINDOW_ORIGINAL", str(Path(__file__).resolve().parents[3]/"client/source/system/nwindow.dll")))
backup = original.with_suffix('.dll.pre-dialog-size.bak')
image = patch((backup if backup.exists() else original).read_bytes())
pe = pefile.PE(data=image)
uc.mem_write(0x10000000,pe.get_memory_mapped_image())
code = 0x10088e7f
outer, inner, vtable, text = 0x200000,0x201000,0x202000,0x203000
header = 0x207000
def dword(address,value): uc.mem_write(address,struct.pack('<I',value))
for obj,w,h in [(outer,300,450),(inner,286,413)]:
    dword(obj,vtable)
    uc.mem_write(obj+0x88,struct.pack('<ff',w,h))
dword(outer+0x1cc,inner)
dword(header,vtable)
dword(outer+0xc0,header)
dword(vtable+0x128,0x10001000)
uc.mem_write(0x10001000,b'\xc2\x08\x00')
uc.mem_write(0x10088440,b'\xc2\x04\x00')
calls=[]
def observe(uc,address,size,user):
    if address==0x10001000:
        obj=uc.reg_read(UC_X86_REG_ECX)
        values=bytes(uc.mem_read(uc.reg_read(UC_X86_REG_ESP)+4,8))
        calls.append((obj,*struct.unpack('<ff',values)))
        uc.mem_write(obj+0x88,values)
uc.hook_add(UC_HOOK_CODE,observe)
for html,expected in [('<!--L2SIZE:03200258--><html/>',(800,600)),('<html/>',(300,450)),('<!--L2SIZE:00010001--><html/>',(300,450)),('<!--L2SIZE:ZZZZ0258--><html/>',(300,450)),('<!--L2SIZE:07800438--><html/>',(1920,1080))]:
    uc.mem_write(text,html.encode('utf-16le')+bytes(100))
    uc.reg_write(UC_X86_REG_ESP,0x30f000)
    uc.reg_write(UC_X86_REG_EAX,text)
    uc.reg_write(UC_X86_REG_ECX,outer)
    uc.emu_start(code,0x10088e8b,count=5000)
    assert calls[-3]==(outer,*expected),calls[-3:]
    assert calls[-2]==(header,expected[0],20),calls[-3:]
    assert calls[-1]==(inner,expected[0]-14,expected[1]-37),calls[-2:]
    assert uc.reg_read(UC_X86_REG_ESP)==0x30f000
    print('PASS',html,expected)
print('Native x86 resize, bounds, malformed input, reset and stack checks passed')

# Exercise the PE's real draw detour and nine-slice machine code, replacing only
# the final engine draw operation. Verify coverage and texture-coordinate bounds.
draw_trampoline = pe.OPTIONAL_HEADER.ImageBase + pe.sections[-1].VirtualAddress + 8192
uc.mem_write(draw_trampoline,b'\xc2\x2c\x00')
texture = 0x204000
dword(texture+0x580, 256)
dword(texture+0x584, 256)
draws=[]
def draw_observe(uc,address,size,user):
    if address==draw_trampoline:
        draws.append(struct.unpack('<11i',uc.mem_read(uc.reg_read(UC_X86_REG_ESP)+4,44)))
uc.hook_add(UC_HOOK_CODE,draw_observe)
for width,height,owner in [(800,600,outer),(500,350,inner),(16,700,inner),(800,600,0x205000),(100,100,outer)]:
    draws.clear()
    stack=0x30e000
    args=(20,30,width,height,0,0,width,height,texture,255,1)
    uc.mem_write(stack,struct.pack('<I11i',0x10000000,*args))
    uc.reg_write(UC_X86_REG_ESP,stack)
    uc.reg_write(UC_X86_REG_ECX,0x206000)
    uc.reg_write(UC_X86_REG_ESI,owner)
    uc.reg_write(UC_X86_REG_EDI,0x206000)
    uc.reg_write(UC_X86_REG_EBX,0)
    uc.emu_start(0x10021a00,0x10000000,count=20000)
    assert uc.reg_read(UC_X86_REG_ESP)==stack+48
    adapted=owner in (outer,inner) and (width>256 or height>256)
    if adapted:
        assert len(draws)==9,draws
        assert sum(d[2]*d[3] for d in draws)==width*height
        for x,y,w,h,u,v,uw,vh,tex,alpha,flags in draws:
            assert 20<=x<=x+w<=20+width
            assert 30<=y<=y+h<=30+height
            assert 0<=u<=u+uw<=256 and 0<=v<=v+vh<=256
            assert (tex,alpha,flags)==(texture,255,1)
        # Interior edges meet exactly, with no gap between cells.
        assert draws[0][0]+draws[0][2]==draws[1][0]
        assert draws[1][0]+draws[1][2]==draws[2][0]
        assert draws[0][1]+draws[0][3]==draws[3][1]
        assert draws[3][1]+draws[3][3]==draws[6][1]
    else:
        assert draws==[args],draws
    print('PASS render',width,height,'NPC' if adapted else 'unchanged')
