#!/bin/bash
set -e

# ===================================================
# GOFILE CONFIGURATION
# Upload target folder: https://gofile.io/d/L5haKk4c
# ===================================================
GOFILE_FOLDER_ID="L5haKk4c"

# 1. Initialize DerpFest 15.2 repository
repo init -u https://github.com/DerpFest-LOS/android_manifest.git -b 15.2 --git-lfs --no-clone-bundle

# 2. Fetch local manifest
mkdir -p .repo/local_manifests
curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" \
    -o .repo/local_manifests/alphaplus.xml

# 3. Sync repositories with force-sync to handle hook mismatches
/opt/crave/resync.sh || repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

# 4. Configure 50G ccache
if command -v ccache >/dev/null 2>&1; then
    ccache --set-config max_size=50G
    ccache --set-config compression=true
    ccache --show-config
else
    apt-get update && apt-get install -y ccache
    ccache --set-config max_size=50G
    ccache --set-config compression=true
    ccache --show-config
fi

# 5. Set build environment flags
export DISABLE_NINJA_SANDBOX=true

# 6. Build DerpFest
source build/envsetup.sh
make installclean
lunch derp_alphaplus-bp1a-userdebug
mka derp

# 7. Locate built zip and upload directly to GoFile link folder
OUT_DIR="out/target/product/alphaplus"
ROM_ZIP=$(find "$OUT_DIR" -maxdepth 1 -type f -name "DerpFest*.zip" ! -name "*ota*.zip" | head -n 1)

if [ -f "$ROM_ZIP" ]; then
    echo "========================================"
    echo "Build success! Found ZIP: $ROM_ZIP"
    echo "Uploading to https://gofile.io/d/$GOFILE_FOLDER_ID..."
    echo "========================================"

    # Ensure dependencies are present
    command -v jq >/dev/null 2>&1 || { apt-get update && apt-get install -y jq; }
    command -v curl >/dev/null 2>&1 || { apt-get update && apt-get install -y curl; }

    # Get active upload server
    SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')

    if [ -n "$SERVER" ] && [ "$SERVER" != "null" ]; then
        # Upload directly to folder ID without token
        RESPONSE=$(curl -s -F "file=@$ROM_ZIP" -F "folderId=$GOFILE_FOLDER_ID" "https://${SERVER}.gofile.io/contents/uploadfile")
        DOWNLOAD_PAGE=$(echo "$RESPONSE" | jq -r '.data.downloadPage')

        echo "========================================"
        echo "Upload Complete!"
        echo "Folder Link: https://gofile.io/d/$GOFILE_FOLDER_ID"
        echo "Direct File Link: $DOWNLOAD_PAGE"
        echo "========================================"
    else
        echo "Error: Could not retrieve a valid GoFile server."
    fi
else
    echo "Error: DerpFest zip file not found in $OUT_DIR."
    exit 1
fi
