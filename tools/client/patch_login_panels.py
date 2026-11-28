"""Apply the login and character menu layout to a compatible Interlude DLL."""

import argparse
from pathlib import Path

EDITS = {
    0x180478: ('6a 17 6a 60 6a 53 6a 0d', '6a 00 6a 00 6a 53 6a 80'),
    0x180596: ('6a 6b 6a 0d', '6a 53 6a 0d'),
    0x13f54d: ('68 8a 00 00 00 6a 78 8b 4d 44 81 c1 38 ff ff ff',
               '68 71 00 00 00 6a 78 8b 4d 44 81 c1 51 ff ff ff'),
    0x17f95d: ('68 8a 00 00 00 81 e9 c8 00 00 00',
               '68 71 00 00 00 81 e9 af 00 00 00'),
    0x17cf26: ('68 71 00 00 00 6a 78', '68 8a 00 00 00 6a 78'),
    0x17ffba: ('68 71 00 00 00 6a 78', '68 8a 00 00 00 6a 78'),
    0x17cbeb: ('6a 17 6a 60 6a 14 6a 0d', '6a 17 6a 60 6a 08 6a 0d'),
    0x17ccf3: ('6a 17 6a 60 6a 2d 6a 0d', '6a 17 6a 60 6a 21 6a 0d'),
    0x17ce0d: ('6a 17 6a 60 6a 5f 6a 0d', '6a 17 6a 60 6a 53 6a 0d'),
}


def patch(data):
    for offset, label in ((0x1804a4, '68 25 03 00 00'), (0x1805be, '68 e3 04 00 00')):
        signature = bytes.fromhex(label)
        if data[offset:offset + len(signature)] != signature:
            raise ValueError(f'Unexpected menu signature at {offset:#x}')

    result = bytearray(data)
    for offset, (previous, updated) in EDITS.items():
        previous, updated = bytes.fromhex(previous), bytes.fromhex(updated)
        end = offset + len(previous)
        if data[offset:end] not in (previous, updated):
            raise ValueError(f'Unexpected instructions at {offset:#x}')
        result[offset:end] = updated
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.output.resolve():
        parser.error('Write the patched DLL to a separate file')
    result = patch(args.source.read_bytes())
    with args.output.open('xb') as output:
        output.write(result)


if __name__ == '__main__':
    main()
