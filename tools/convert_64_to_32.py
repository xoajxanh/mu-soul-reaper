import struct
import sys
import os

def convert_file(in_path, out_path):
    with open(in_path, 'rb') as f:
        data = f.read()

    idx = 0
    out = bytearray()

    def read_fmt(fmt):
        nonlocal idx
        s = struct.calcsize(fmt)
        val = struct.unpack_from(fmt, data, idx)
        idx += s
        return val[0] if len(val) == 1 else val

    def read_bytes(n):
        nonlocal idx
        val = data[idx:idx+n]
        idx += n
        return val

    # HEADER
    header = read_bytes(17)
    # Check signature
    if header[0:4] != b'\x1bLua':
        raise Exception("Not Lua bytecode")
    
    # We will modify header to size_t = 4
    new_header = bytearray(header)
    new_header[13] = 4 # size_t
    out.extend(new_header)
    
    out.extend(read_bytes(16)) # LUAC_INT (8) + LUAC_NUM (8)
    
    size_upvalues = read_fmt('B')
    out.extend(struct.pack('B', size_upvalues))

    def write_size_t_32(val):
        out.extend(struct.pack('<I', val))

    def write_bytes(b):
        out.extend(b)

    def write_int(val):
        out.extend(struct.pack('<i', val))

    def write_byte(val):
        out.extend(struct.pack('B', val))

    def convert_string():
        size = read_fmt('B')
        write_byte(size)
        if size == 0:
            return
        if size == 0xFF:
            str_len = read_fmt('<Q') # 8-byte size_t
            write_size_t_32(str_len)
            str_len -= 1 # actual string length is size - 1
            write_bytes(read_bytes(str_len))
        else:
            str_len = size - 1
            write_bytes(read_bytes(str_len))

    def convert_function():
        convert_string() # source name
        write_int(read_fmt('<i')) # lineDefined
        write_int(read_fmt('<i')) # lastLineDefined
        write_byte(read_fmt('B')) # numParams
        write_byte(read_fmt('B')) # is_vararg
        write_byte(read_fmt('B')) # maxStackSize

        # code
        sizeCode = read_fmt('<i')
        write_int(sizeCode)
        write_bytes(read_bytes(sizeCode * 4))

        # constants
        sizeK = read_fmt('<i')
        write_int(sizeK)
        for _ in range(sizeK):
            t = read_fmt('B')
            write_byte(t)
            tt = t & 0x3F # base type
            if tt == 0: # Nil
                pass
            elif tt == 1: # Bool
                write_byte(read_fmt('B'))
            elif tt == 3: # Integer (8 bytes)
                write_bytes(read_bytes(8))
            elif tt == 19: # Float (8 bytes)
                write_bytes(read_bytes(8))
            elif tt == 4 or tt == 20: # String (4) or Long String (20)
                convert_string()
            else:
                raise Exception(f"Unknown constant type {t}")

        # upvalues
        sizeUpvalues = read_fmt('<i')
        write_int(sizeUpvalues)
        for _ in range(sizeUpvalues):
            write_bytes(read_bytes(2)) # inStack, idx

        # protos
        sizeProtos = read_fmt('<i')
        write_int(sizeProtos)
        for _ in range(sizeProtos):
            convert_function()

        # debug info
        sizeLineInfo = read_fmt('<i')
        write_int(sizeLineInfo)
        write_bytes(read_bytes(sizeLineInfo * 4))

        sizeLocVars = read_fmt('<i')
        write_int(sizeLocVars)
        for _ in range(sizeLocVars):
            convert_string()
            write_int(read_fmt('<i'))
            write_int(read_fmt('<i'))

        sizeUpvalueNames = read_fmt('<i')
        write_int(sizeUpvalueNames)
        for _ in range(sizeUpvalueNames):
            convert_string()

    convert_function()
    
    with open(out_path, 'wb') as f:
        f.write(out)
    print(f"Successfully converted {os.path.basename(in_path)} to 32-bit size_t bytecode.")

if __name__ == '__main__':
    convert_file(sys.argv[1], sys.argv[2])
