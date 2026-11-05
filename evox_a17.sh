#!/bin/bash
set -e
[ -d .repo/local_manifests ] && mv .repo/local_manifests .repo/local_manifests.bak.$(date +%s)

repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs
git clone https://github.com/protpr0t/local_manifest_alphaplus -b evox-17 .repo/local_manifests
/opt/crave/resync.sh
export EVO_BUILD_TYPE=UNOFFICIAL
. build/envsetup.sh
lunch lineage_alphaplus-cp2a-eng
m installclean
m evolution
