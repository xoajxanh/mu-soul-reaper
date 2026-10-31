import os
import subprocess
import tempfile
from concurrent.futures import ThreadPoolExecutor

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_DIR = os.path.join(PROJECT_ROOT, "extracted")
DEST_DIR = os.path.join(PROJECT_ROOT, "extracted", "luas")
UNLUAC_JAR = os.path.join(PROJECT_ROOT, "tools", "unluac.jar")
JAVA_EXE = r"C:\Program Files\Java\jdk-26.0.1\bin\java.exe"
if not os.path.exists(JAVA_EXE):
    JAVA_EXE = "java"

os.makedirs(DEST_DIR, exist_ok=True)

files_to_process = [
    os.path.join(SRC_DIR, f)
    for f in os.listdir(SRC_DIR)
    if os.path.isfile(os.path.join(SRC_DIR, f)) and (f.endswith(".lua") or f.endswith(".bytes"))
]

def process_file(filepath):
    filename = os.path.basename(filepath)
    outpath = os.path.join(DEST_DIR, filename)

    try:
        with open(filepath, "rb") as f:
            raw_bytes = f.read()

        # Check if Lua bytecode
        if len(raw_bytes) > 15 and raw_bytes[0:4] == b"\x1bLua":
            data = bytearray(raw_bytes)
            if data[5] == 1:
                data[5] = 0
                data.insert(14, 4)

            fd, patched_path = tempfile.mkstemp(suffix=".luac")
            try:
                with os.fdopen(fd, "wb") as tf:
                    tf.write(data)

                cmd = [JAVA_EXE, "-XX:-UsePerfData", "-jar", UNLUAC_JAR, patched_path]
                result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
                if result.returncode == 0:
                    with open(outpath, "w", encoding="utf-8") as out_f:
                        out_f.write(result.stdout)
                    return (filename, True, "decompiled")
                else:
                    return (filename, False, f"unluac error: {result.stderr.strip()}")
            finally:
                if os.path.exists(patched_path):
                    try:
                        os.remove(patched_path)
                    except OSError:
                        pass
        else:
            # Plain text (e.g. proto3 definitions)
            with open(outpath, "wb") as out_f:
                out_f.write(raw_bytes)
            return (filename, True, "copied_text")
    except Exception as e:
        return (filename, False, f"exception: {e}")

def main():
    total = len(files_to_process)
    print(f"Tim thay {total} files trong {SRC_DIR}. Bat dau decompile sang {DEST_DIR} ...")
    success = 0
    decompiled_count = 0
    copied_count = 0
    failed = []

    with ThreadPoolExecutor(max_workers=16) as executor:
        for idx, (fname, ok, msg) in enumerate(executor.map(process_file, files_to_process), 1):
            if ok:
                success += 1
                if msg == "decompiled":
                    decompiled_count += 1
                else:
                    copied_count += 1
            else:
                failed.append((fname, msg))

            if idx % 250 == 0 or idx == total:
                print(f"  -> Tien do: {idx}/{total} (Thanh cong: {success}, Loi: {len(failed)})", flush=True)

    print(f"\nHoan tat! Tong cong: {success}/{total} files (Decompiled bytecode: {decompiled_count}, Plain text/proto: {copied_count}).")
    if failed:
        print(f"So file loi ({len(failed)}):")
        for fname, err in failed[:20]:
            print(f"  [FAIL] {fname}: {err}")

if __name__ == "__main__":
    main()

