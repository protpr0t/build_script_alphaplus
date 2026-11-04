#!/bin/bash
set -e

WORK_DIR=$(pwd)

[ -d .repo/local_manifests ] && mv .repo/local_manifests .repo/local_manifests.bak.$(date +%s)

repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs
git clone https://github.com/protpr0t/local_manifest_alphaplus -b evox-17 .repo/local_manifests

/opt/crave/resync.sh

if [ ! -f .keys_generated ]; then
    echo "[LOG 1] Menyiapkan Evolution X Private Keys di: $(pwd)"
    
    # Jika folder vendor/evolution-priv/keys belum ada dari resync, clone template resmi
    if [ ! -d vendor/evolution-priv/keys ]; then
        git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
    fi

    echo "[LOG 2] Masuk ke folder keys: $(pwd)"
    cd vendor/evolution-priv/keys
    
    echo "[LOG 3] Menjalankan keys.sh di: $(pwd)"
    bash keys.sh || true
    
    echo "[LOG 4] Kembali ke root workspace..."
    cd "$WORK_DIR"
    
    echo "[LOG 5] Membuat file marker di: $(pwd)"
    touch .keys_generated
    
    echo "[LOG 6] Proses generate keys selesai. Posisi terminal: $(pwd)"
fi

export EVO_BUILD_TYPE=UNOFFICIAL

. build/envsetup.sh
lunch lineage_alphaplus-cp2a-eng
m installclean
m evolution
