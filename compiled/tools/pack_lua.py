import os
import hashlib
import UnityPy

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_BUNDLE = os.path.join(PROJECT_ROOT, "base", "lua.mu2")
SRC_BUNDLES_TXT = os.path.join(PROJECT_ROOT, "base", "bundles.txt")
COMPILED_LUAC_DIR = os.path.join(PROJECT_ROOT, "compiled", "luac")
DEST_BUNDLE = os.path.join(PROJECT_ROOT, "compiled", "lua.mu2")
DEST_BUNDLES_TXT = os.path.join(PROJECT_ROOT, "compiled", "bundles.txt")
BUNDLE_VERSION = os.environ.get("BUNDLE_VERSION", "99")

os.makedirs(os.path.dirname(DEST_BUNDLE), exist_ok=True)

print(f"Loading base bundle: {SRC_BUNDLE} ...")
env = UnityPy.load(SRC_BUNDLE)

files = {}
for root, _, filenames in os.walk(COMPILED_LUAC_DIR):
    for f in filenames:
        files[f.lower()] = os.path.join(root, f)

if not files:
    raise RuntimeError(f"[ERROR] No compiled Lua files found in {COMPILED_LUAC_DIR} to pack!")

replaced = 0
for obj in env.objects:
    if obj.type.name == "TextAsset":
        data = obj.read()
        name = data.m_Name

        search_name = name.lower()
        if not search_name.endswith(".lua") and not search_name.endswith(".txt") and not search_name.endswith(".bytes"):
            search_name += ".lua"

        if search_name in files:
            with open(files[search_name], "rb") as f:
                new_bytes = bytearray(f.read())

            data.m_Script = new_bytes.decode("utf-8", "surrogateescape")
            data.save()
            replaced += 1
            print(f"  [OK] Injected into bundle: {name}")

if replaced == 0:
    raise RuntimeError(f"[ERROR] 0 TextAssets replaced in {SRC_BUNDLE}! Check compiled file names.")

print(f"-> Successfully replaced {replaced} TextAsset(s) in bundle.")
print("Saving and packing to LZ4...")
with open(DEST_BUNDLE, "wb") as f:
    if hasattr(env, "file"):
        f.write(env.file.save(packer="lz4"))
    else:
        f.write(list(env.files.values())[0].save(packer="lz4"))

print(f"-> Saved packed bundle to: {DEST_BUNDLE}")

# Update bundles.txt with new MD5 and size
if os.path.exists(SRC_BUNDLES_TXT):
    with open(DEST_BUNDLE, "rb") as bf:
        bundle_bytes = bf.read()
    md5_hash = hashlib.md5(bundle_bytes).hexdigest().lower()
    bundle_size = len(bundle_bytes)

    with open(SRC_BUNDLES_TXT, "r", encoding="utf-8") as f:
        lines = f.readlines()

    with open(DEST_BUNDLES_TXT, "w", encoding="utf-8", newline="\n") as f:
        for line in lines:
            if line.startswith("lua.mu2|"):
                f.write(f"lua.mu2|0|{md5_hash}|{bundle_size}|{BUNDLE_VERSION}\n")
            else:
                f.write(line)

    print(f"-> Updated bundles.txt: lua.mu2|0|{md5_hash}|{bundle_size}|{BUNDLE_VERSION}")

