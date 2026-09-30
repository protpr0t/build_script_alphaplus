#!/bin/bash
set -e

# 1. Hapus hanya folder local_manifests untuk pembersihan awal
rm -rf .repo/local_manifests

# 2. Inisialisasi repository crDroid 15.0
repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --depth=1 --git-lfs --no-clone-bundle

# 3. Pull local manifest langsung dari protpr0t
mkdir -p .repo/local_manifests
curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" \
    -o .repo/local_manifests/alphaplus.xml

# Ganti referensi remote private (rainbowdashh/TheMuppets) ke LineageOS publik
sed -i 's|rainbowdashh|LineageOS|g' .repo/local_manifests/alphaplus.xml || true
sed -i 's|TheMuppets|LineageOS|g' .repo/local_manifests/alphaplus.xml || true

# 4. Sinkronisasi repository menggunakan Crave resync
/opt/crave/resync.sh

# 5. Patch ContactsProvider SQLiteTokenizer compilation error
CP_TARGET="packages/providers/ContactsProvider/src/com/android/providers/contacts/util/SelectionBuilder.java"

if [ -f "$CP_TARGET" ]; then
    if grep -q 'SQLiteTokenizer\.OPTION_CHECK_BRACKETS' "$CP_TARGET"; then
        echo "=== Patching ContactsProvider SelectionBuilder.java ==="
        sed -i 's/SQLiteTokenizer\.OPTION_CHECK_BRACKETS/0/g' "$CP_TARGET"
    else
        echo "OPTION_CHECK_BRACKETS not found, patch not required."
    fi
else
    echo "Warning: $CP_TARGET not found, skipping patch."
fi

# 6. Konfigurasi CCACHE (30GB Limit)
if command -v ccache >/dev/null 2>&1; then
    export USE_CCACHE=1
    export CCACHE_EXEC=$(which ccache)
    export CCACHE_DIR="${HOME}/.ccache"
    ccache --set-config max_size=30G
    ccache --set-config compression=true
    echo "=== CCACHE Configuration ==="
    ccache --show-config
fi

# 7. Environment flags & Jalankan Build dengan brunch alphaplus
export DISABLE_NINJA_SANDBOX=true
source build/envsetup.sh
make installclean

brunch alphaplus

# 8. Unggah berkas hasil build ke GoFile.io
OUT_DIR="out/target/product/alphaplus"
ZIP_FILE=$(find "${OUT_DIR}" -maxdepth 1 -type f -name "crDroidAndroid-*.zip" ! -name "*ota*.zip" | head -n 1)

if [ -f "$ZIP_FILE" ]; then
    ZIP_NAME=$(basename "$ZIP_FILE")
    echo "Build berhasil! Mengunggah ${ZIP_NAME} ke GoFile..."

    SERVER=$(curl -s https://api.gofile.io/servers | grep -o '"name":"[^"]*"' | head -n 1 | cut -d'"' -f4)
    if [ -z "$SERVER" ]; then
        SERVER="store1"
    fi

    UPLOAD_RESPONSE=$(curl -s -F "file=@${ZIP_FILE}" "https://${SERVER}.gofile.io/contents/uploadfile")
    DOWNLOAD_PAGE=$(echo "$UPLOAD_RESPONSE" | grep -o '"downloadPage":"[^"]*"' | cut -d'"' -f4)

    echo "========================================="
    echo "Build crDroid Selesai!"
    echo "File: ${ZIP_NAME}"
    echo "Download Link: ${DOWNLOAD_PAGE}"
    echo "========================================="
else
    echo "Error: Berkas zip crDroid tidak ditemukan di ${OUT_DIR}."
    exit 1
fi
