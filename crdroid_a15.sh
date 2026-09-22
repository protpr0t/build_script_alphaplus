rm -rf .repo/local_manifests/
rm -rf device/lge
rm -rf kernel/lge
rm -rf vendor/lge
rm -rf hardware/lge
rm -rf out/target/product/alphaplus

rm -rf out/target/product/*/system/etc/Changelog.txt \
       out/target/product/*/obj/ETC/Changelog.txt_intermediates \
       out/target/product/*/gen/ETC/Changelog.txt_intermediates

repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --depth=1 --git-lfs --no-clone-bundle

mkdir -p .repo/local_manifests
curl -s -L "https://raw.githubusercontent.com/protpr0t/local_manifest_alphaplus/main/local_manifest.xml" -o .repo/local_manifests/alphaplus.xml

/opt/crave/resync.sh

source build/envsetup.sh

brunch alphaplus
