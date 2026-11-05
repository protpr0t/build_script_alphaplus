#!/bin/bash
set -e
[ -d .repo/local_manifests ] && mv .repo/local_manifests .repo/local_manifests.bak.$(date +%s)

repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 17 -g default,-mips,-darwin,-notdefault
git clone https://github.com/protpr0t/local_manifest_alphaplus -b infinity-17 .repo/local_manifests
/opt/crave/resync.sh

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
