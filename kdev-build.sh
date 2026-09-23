#!/bin/bash

set -ex

# build kernel Image
make ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  KBUILD_BUILD_USER="builder" \
  KBUILD_BUILD_HOST="kdevbuilder" \
  LOCALVERSION=-kdev \
  bdy_g98_rk3588_defconfig

make ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  KBUILD_BUILD_USER="builder" \
  KBUILD_BUILD_HOST="kdevbuilder" \
  LOCALVERSION=-kdev \
  olddefconfig

# check kver
KVER=$(make LOCALVERSION=-kdev kernelrelease)
KVER="${KVER/kdev*/kdev}"
if [[ "$KVER" != *kdev ]]; then
  echo "ERROR: KVER does not end with 'kdev'"
  exit 1
fi
echo "KVER: ${KVER}"

make ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  KBUILD_BUILD_USER="builder" \
  KBUILD_BUILD_HOST="kdevbuilder" \
  LOCALVERSION=-kdev \
  dtbs \
   -j$(nproc)


make ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  KBUILD_BUILD_USER="builder" \
  KBUILD_BUILD_HOST="kdevbuilder" \
  LOCALVERSION=-kdev \
  KCFLAGS="-Wno-unused-function" \
   -j$(nproc)

make ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  KBUILD_BUILD_USER="builder" \
  KBUILD_BUILD_HOST="kdevbuilder" \
  LOCALVERSION=-kdev \
  KCFLAGS="-Wno-unused-function" \
  modules -j$(nproc)

# release kernel image
ls -alh arch/arm64/boot/Image
md5sum arch/arm64/boot/Image
cp -a arch/arm64/boot/Image ${WORKDIR}/release/

# release dtb
ls -alh ./arch/arm64/boot/dts/rockchip/rk3588-bdy-g98.dtb
md5sum ./arch/arm64/boot/dts/rockchip/rk3588-bdy-g98.dtb
cp -a ./arch/arm64/boot/dts/rockchip/rk3588-bdy-g98.dtb ${WORKDIR}/release/

# release config
cp .config ${WORKDIR}/release/config
ls -alh ${WORKDIR}/release/config
md5sum ${WORKDIR}/release/config

# release system map
cp System.map ${WORKDIR}/release/System.map
ls -alh ${WORKDIR}/release/System.map
md5sum ${WORKDIR}/release/System.map

# release kernel modules
if [ -d kos/lib/modules ]; then
  dir_size=$(du -sb kos/lib/modules | awk '{print $1}')
  if [ "$dir_size" -gt 512 ]; then
    cp -a kos kos-debug
    find kos -name "*.ko" -print0 | xargs -0 -r aarch64-linux-gnu-strip --strip-debug
    find kos -name "*.ko"
    ls -alh kos/lib/modules/
    mkdir -p "${WORKDIR}/release"
    tar -zcvf "${WORKDIR}/release/kos.tar.gz" kos
    tar -zcvf "${WORKDIR}/release/kos-debug.tar.gz" kos-debug
  fi
fi

# archive kernel debuginfo
if [ -f vmlinux ]; then
    mkdir -p "${WORKDIR}/release"

    DEBUGINFO_FILES=()
    for f in vmlinux vmlinux.unstripped System.map Module.symvers .config; do
        [ -f "$f" ] && DEBUGINFO_FILES+=("$f")
    done

    if [ ${#DEBUGINFO_FILES[@]} -gt 0 ]; then
        tar -zcvf "${WORKDIR}/release/kernel-debuginfo.tar.gz" "${DEBUGINFO_FILES[@]}"
        echo "Kernel debuginfo archived: ${DEBUGINFO_FILES[*]}"
    else
        echo "No debuginfo files found to archive"
    fi
fi

ls -alh ${WORKDIR}/release/
echo "Build completed successfully!"
exit 0
