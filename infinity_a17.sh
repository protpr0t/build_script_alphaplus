#!/bin/bash
set -e
WORK_DIR="$(pwd)"
[ -d .repo/local_manifests ] && mv .repo/local_manifests .repo/local_manifests.bak.$(date +%s)

repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 17 -g default,-mips,-darwin,-notdefault
git clone https://github.com/protpr0t/local_manifest_alphaplus -b infinity-17 .repo/local_manifests
/opt/crave/resync.sh

# Otomatisasi generate private keys
KEYS_DIR="vendor/infinity-priv/keys"
KEYS_TEMPLATE="https://github.com/ProjectInfinity-X/vendor_infinity-priv_keys-template"

if [ ! -f .keys_generated ] || [ ! -f "$KEYS_DIR/releasekey.pk8" ]; then
    echo "[LOG 1] Menyiapkan Infinity X Private Keys di: $(pwd)"

    # Folder dari resync bukan template (tidak ada keys.sh) -> pindahkan ke backup di luar source tree
    if [ -d "$KEYS_DIR" ] && [ ! -f "$KEYS_DIR/keys.sh" ]; then
        echo "[LOG 2] $KEYS_DIR bukan template yang valid, dipindah ke backup"
        mv "$KEYS_DIR" "/tmp/infinity-priv-keys.bak.$(date +%s)"
    fi

    # Clone template resmi kalau folder belum ada
    if [ ! -d "$KEYS_DIR" ]; then
        git clone "$KEYS_TEMPLATE" "$KEYS_DIR"
    fi

    echo "[LOG 3] Menjalankan keys.sh di: $KEYS_DIR"
    (cd "$KEYS_DIR" && yes '' | bash keys.sh) || true

    # Gagal cepat kalau key tidak terbentuk
    if [ ! -f "$KEYS_DIR/releasekey.pk8" ]; then
        echo "ERROR: keys.sh tidak menghasilkan releasekey.pk8" >&2
        exit 1
    fi

    echo "[LOG 4] Membuat file marker di: $(pwd)"
    touch .keys_generated
    echo "[LOG 5] Proses generate keys selesai"
fi

# Gagal cepat kalau keys.mk rusak (error "missing separator")
if make -n -f "$KEYS_DIR/keys.mk" 2>&1 | grep -q "missing separator"; then
    echo "ERROR: $KEYS_DIR/keys.mk tidak valid" >&2
    exit 1
fi

export INFINITY_BUILD_TYPE=UNOFFICIAL
export INFINITY_MAINTAINER=protpr0t

# Build flags (GApps build)
export TARGET_SUPPORTS_BLUR=true
export TARGET_HAS_UDFPS=false
export WITH_GAPPS=true
export TARGET_BUILD_GOOGLE_TELEPHONY=true
export TARGET_SUPPORTS_TOUCHGESTURES=true
export USE_MOTO_CALCULATOR=true

. build/envsetup.sh
lunch infinity_alphaplus-cp2a-eng
m installclean
m bacon
