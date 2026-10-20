#!/bin/bash
set -e

repo init -u https://github.com/DerpFest-LOS/android_manifest.git -b 15.2 --git-lfs --no-clone-bundle

mkdir -p .repo/local_manifests
curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" -o .repo/local_manifests/alphaplus.xml

/opt/crave/resync.sh

# Install ccache before configuring it
sudo apt-get update
sudo apt-get install -y ccache

# Robust ccache setup for Crave
export CCACHE_DIR=$(pwd)/.ccache
export USE_CCACHE=1
export CCACHE_EXEC=$(which ccache)
$CCACHE_EXEC -M 50G

# Force Soong to use the system's ninja binary
export SOONG_NINJA=ninja

source build/envsetup.sh
make installclean
lunch derp_alphaplus-ap3a-userdebug
mka derp
