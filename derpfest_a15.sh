#!/bin/bash
set -e

# Define a custom destroy function
destroy() {
    if [ -d "$1" ]; then
        rm -rf "$1"
    fi
}

repo init -u https://github.com/DerpFest-LOS/android_manifest.git -b 15.2 --git-lfs --no-clone-bundle --depth=1

# Check if the folder is a valid Git repository; if not, destroy and clone fresh
if [ -d ".repo/local_manifests/.git" ]; then
    git -C .repo/local_manifests pull
else
    destroy ".repo/local_manifests"
    git clone --depth=1 https://github.com/protpr0t/local_manifest_alphaplus.git .repo/local_manifests
fi

/opt/crave/resync.sh

sudo apt-get update
sudo apt-get install -y ccache
export CCACHE_DIR=$(pwd)/.ccache
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
/usr/bin/ccache -M 30G

export SOONG_NINJA=ninja

source build/envsetup.sh

export DERP_BUILD_TYPE=UNOFFICIAL

export WITH_GAPPS=false

lunch derp_alphaplus-ap3a-userdebug

make installclean
mka derp
