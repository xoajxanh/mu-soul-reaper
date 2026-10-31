import os
import UnityPy

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_BUNDLE = os.path.join(PROJECT_ROOT, "decompiled", "resources", "assets", "Bundles", "lua.mu2")
DEST_DIR = os.path.join(PROJECT_ROOT, "extracted")

def extract_assets(src, dest):
    if not os.path.exists(src):
        raise FileNotFoundError(f"Khong tim thay bundle tai: {src}")

    print(f"Dang doc bundle: {src} ...")
    env = UnityPy.load(src)
    os.makedirs(dest, exist_ok=True)
    count = 0

    for obj in env.objects:
        if obj.type.name == "TextAsset":
            data = obj.read()
            name = data.m_Name
            script = data.m_Script
            if isinstance(script, str):
                script = script.encode("utf-8", "surrogateescape")

            filename = name
            if not filename.endswith(".lua") and not filename.endswith(".bytes"):
                filename += ".lua"

            filepath = os.path.join(dest, filename)
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            with open(filepath, "wb") as f:
                f.write(script)
            count += 1

    print(f"Hoan tat! Da extract {count} TextAssets vao: {dest}")

if __name__ == "__main__":
    extract_assets(SRC_BUNDLE, DEST_DIR)

