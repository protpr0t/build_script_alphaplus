#!/bin/bash
set -e
WORK_DIR="$(pwd)"
[ -d .repo/local_manifests ] && mv .repo/local_manifests .repo/local_manifests.bak.$(date +%s)

repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 17 -g default,-mips,-darwin,-notdefault
git clone https://github.com/protpr0t/local_manifest_alphaplus -b infinity-17 .repo/local_manifests
/opt/crave/resync.sh

# Otomatisasi generate private keys
if [ ! -f .keys_generated ]; then
    echo "[LOG 1] Menyiapkan Infinity X Private Keys di: $(pwd)"

    # Jika folder vendor/infinity-priv/keys belum ada dari resync, clone template resmi
    if [ ! -d vendor/infinity-priv/keys ]; then
        git clone https://github.com/ProjectInfinity-X/vendor_infinity-priv_keys-template vendor/infinity-priv/keys
    fi

    echo "[LOG 2] Masuk ke folder keys: $(pwd)"
    cd vendor/infinity-priv/keys

    echo "[LOG 3] Menjalankan keys.sh di: $(pwd)"
    bash keys.sh || true

    echo "[LOG 4] Kembali ke root workspace..."
    cd "$WORK_DIR"

    echo "[LOG 5] Membuat file marker di: $(pwd)"
    touch .keys_generated

    echo "[LOG 6] Proses generate keys selesai. Posisi terminal: $(pwd)"
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
