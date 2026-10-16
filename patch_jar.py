"""Copies the DrJava jar, keeping the Interactions JVM's debugger port on this Mac.

DrJava starts the JVM that runs your code with
"-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=<port>". On Java 8 a bare port
listens on every network interface, and JDWP has no password, so anyone on the same Wi-Fi
could run code through it while DrJava is open. Prefixing 127.0.0.1 keeps it on this Mac.
DrJava's own debugger already attaches to 127.0.0.1, so debugging still works.

Usage: python3 -I patch_jar.py <official drjava.jar> <output jar>
"""
import struct
import sys
import zipfile

CLASS = 'edu/rice/cs/drjava/model/repl/newjvm/MainJVM.class'
OLD = b'-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address='
NEW = b'-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=127.0.0.1:'
# Constant pool entry sizes by tag, for every tag except Utf8 (1).
SIZES = {3: 5, 4: 5, 5: 9, 6: 9, 7: 3, 8: 3, 9: 5, 10: 5, 11: 5, 12: 5,
         15: 4, 16: 3, 17: 5, 18: 5, 19: 3, 20: 3}


def patch_class(data):
    """Rewrites one Utf8 constant. Everything else refers to it by index, so nothing moves."""
    assert data[:4] == b'\xca\xfe\xba\xbe', 'not a class file'
    count = struct.unpack('>H', data[8:10])[0]
    i, k, hits = 10, 1, 0
    out = bytearray(data[:10])
    while k < count:
        tag = data[i]
        if tag == 1:
            length = struct.unpack('>H', data[i + 1:i + 3])[0]
            text = data[i + 3:i + 3 + length]
            if text == OLD:
                text, hits = NEW, hits + 1
            out += bytes([1]) + struct.pack('>H', len(text)) + text
            i += 3 + length
        else:
            out += data[i:i + SIZES[tag]]
            i += SIZES[tag]
            if tag in (5, 6):  # long and double constants take two slots
                k += 1
        k += 1
    if hits != 1:
        sys.exit(f'expected the debugger setting once in {CLASS}, found it {hits} times')
    return bytes(out + data[i:])


def main(src, dst):
    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, 'w') as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            if info.filename == CLASS:
                data = patch_class(data)
            zout.writestr(info, data, compress_type=info.compress_type)


if __name__ == '__main__':
    main(*sys.argv[1:3])
