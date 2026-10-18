#!/bin/bash
set -e

if [ ! -f /swapfile ]; then
    sudo fallocate -l 32G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo sysctl vm.swappiness=10
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
fi

repo init -u https://github.com/DerpFest-LOS/android_manifest.git -b 15.2 --git-lfs --no-clone-bundle

mkdir -p .repo/local_manifests
curl -fL "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" -o .repo/local_manifests/alphaplus.xml

/opt/crave/resync.sh

export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 50G

source build/envsetup.sh
make installclean
lunch derp_alphaplus-bp1a-userdebug
mka derp
