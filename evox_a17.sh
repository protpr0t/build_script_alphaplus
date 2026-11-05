#!/bin/bash
set -e
WORK_DIR="$(pwd)"
[ -d .repo/local_manifests ] && mv .repo/local_manifests .repo/local_manifests.bak.$(date +%s)

repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs
git clone https://github.com/protpr0t/local_manifest_alphaplus -b evox-17 .repo/local_manifests
/opt/crave/resync.sh

# Otomatisasi generate private keys
KEYS_DIR="vendor/evolution-priv/keys"
KEYS_TEMPLATE="https://github.com/Evolution-X/vendor_evolution-priv_keys-template"

if [ ! -f .keys_generated ] || [ ! -f "$KEYS_DIR/releasekey.pk8" ]; then
    echo "[LOG 1] Menyiapkan Evolution X Private Keys di: $(pwd)"

    # Folder dari resync bukan template (tidak ada keys.sh) -> pindahkan ke backup di luar source tree
    if [ -d "$KEYS_DIR" ] && [ ! -f "$KEYS_DIR/keys.sh" ]; then
        echo "[LOG 2] $KEYS_DIR bukan template yang valid, dipindah ke backup"
        mv "$KEYS_DIR" "/tmp/evolution-priv-keys.bak.$(date +%s)"
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

export EVO_BUILD_TYPE=UNOFFICIAL

. build/envsetup.sh
lunch lineage_alphaplus-cp2a-eng
m installclean
m evolution
