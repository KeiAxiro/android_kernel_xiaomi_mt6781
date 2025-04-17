#!/bin/bash
#
# Kernel build script for Poco M4 Pro (fleur)
# by keidjaru

SECONDS=0

# Nama output zip
ZIPNAME="CPU_OCUV-GPU_OCUV-keidjaru-kernel-fleur-$(date '+%Y%m%d-%H%M').zip"

# Path ke toolchain dan AnyKernel3
TC_DIR="$HOME/project/kernel/linux-x86/clang-r547379"
AK3_DIR="$HOME/android/AnyKernel3"
DEFCONFIG="fleur_defconfig"

# Tambahkan Clang ke PATH
export PATH="$TC_DIR/bin:$PATH"

# Cek & clone Clang jika belum ada
if ! [ -d "$TC_DIR" ]; then
    echo "[!] Clang tidak ditemukan, cloning ke $TC_DIR..."
    if ! git clone --depth=1 https://github.com/kdrag0n/proton-clang "$TC_DIR"; then
        echo "[x] Gagal cloning toolchain! Abort."
        exit 1
    fi
fi

# Build info
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=keidjaru
export KBUILD_BUILD_HOST=ubuntu

# Regen defconfig (opsional)
if [[ $1 = "-r" || $1 = "--regen" ]]; then
    make O=out ARCH=arm64 "$DEFCONFIG" savedefconfig
    cp out/defconfig arch/arm64/configs/"$DEFCONFIG"
    echo "[i] Defconfig berhasil diregenerasi."
    exit 0
fi

# Mulai build
mkdir -p out
make O=out ARCH=arm64 "$DEFCONFIG"

echo -e "\n[+] Mulai kompilasi kernel...\n"
make -j$(nproc) O=out \
    ARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    AS=llvm-as \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    Image.gz-dtb 2>&1 | tee build.log

# Cek hasil dan zip
if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
    echo -e "\n[✓] Kernel berhasil dikompilasi! Membuat zip...\n"

    if [ -d "$AK3_DIR" ]; then
        cp -r "$AK3_DIR" AnyKernel3
    elif ! git clone -q https://github.com/in1tialford/AnyKernel3; then
        echo "[x] Gagal clone AnyKernel3! Abort."
        exit 1
    fi

    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3/
    rm -f "$ZIPNAME"
    cd AnyKernel3 || exit 1
    zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
    cd ..
    rm -rf AnyKernel3

    echo -e "\n[✓] Build selesai dalam $((SECONDS / 60))m $((SECONDS % 60))s"
    echo "[✓] Output: $ZIPNAME"

    # Opsional upload ke oshi.at
    if command -v curl &> /dev/null; then
        echo "[i] Uploading to oshi.at..."
        curl --upload-file "$ZIPNAME" "https://oshi.at/$ZIPNAME"
        echo
    fi
else
    echo -e "\n[x] Build gagal! Cek error log di atas."
    exit 1
fi
