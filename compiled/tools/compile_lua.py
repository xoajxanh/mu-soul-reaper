import os
import sys
import subprocess

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODIFIED_DIR = os.environ.get("LUA_SRC_DIR", os.path.join(PROJECT_ROOT, "dev", "client"))
if not os.path.isabs(MODIFIED_DIR):
    MODIFIED_DIR = os.path.join(PROJECT_ROOT, MODIFIED_DIR)

COMPILED_DIR = os.path.join(PROJECT_ROOT, "compiled", "luac")
LUAC_EXE = os.path.join(PROJECT_ROOT, "tools", "lua53", "luac53.exe")
CONVERT_PY = os.path.join(PROJECT_ROOT, "tools", "convert_64_to_32.py")

os.makedirs(COMPILED_DIR, exist_ok=True)

if not os.path.isdir(MODIFIED_DIR):
    raise RuntimeError(f"[ERROR] Source Lua directory does not exist: {MODIFIED_DIR}")

count = 0
for root, _, files in os.walk(MODIFIED_DIR):
    for f in files:
        if f.endswith(".lua"):
            src_path = os.path.join(root, f)
            dest_path = os.path.join(COMPILED_DIR, f)

            # 1. Compile Lua 5.3
            subprocess.run([LUAC_EXE, "-o", dest_path, src_path], check=True)

            # 2. Convert 64-bit size_t to 32-bit size_t
            subprocess.run([sys.executable, CONVERT_PY, dest_path, dest_path], check=True)

            # 3. Patch custom xLua 5.3 header
            with open(dest_path, "rb") as file:
                data = bytearray(file.read())

            if data[0:4] == b"\x1bLua":
                data[5] = 0x01  # Format byte
                del data[14]    # Remove instruction size byte

                with open(dest_path, "wb") as file:
                    file.write(data)

            count += 1
            print(f"  [OK] Compiled: {f}")

if count == 0:
    raise RuntimeError(f"[ERROR] No .lua files found in: {MODIFIED_DIR}")

print(f"-> Successfully compiled {count} Lua file(s) to {COMPILED_DIR}")

