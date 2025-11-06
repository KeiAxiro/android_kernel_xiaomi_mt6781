#!/bin/bash
#
# Kernel Build Script for Poco M4 Pro (fleur)
# Offline-ready version by Keidjaru
# Because internet’s not always your friend.

set -e
cd "$(dirname "$0")" || exit 1

# ======================
#  CONFIGURATION
# ======================

SECONDS=0
DEFCONFIG="fleur_defconfig"
TC_DIR="linux-x86/clang-r547379"
AK3_DIR="android/AnyKernel3"  
ZIPNAME="normal-KeiAxiro-kernel-fleur-$(date '+%Y%m%d-%H%M').zip"

# ======================
#  COLORS
# ======================

RED="\e[31m"
GRN="\e[32m"
YLW="\e[33m"
CYN="\e[36m"
RST="\e[0m"

say()  { echo -e "${CYN}[i]${RST} $*"; }
good() { echo -e "${GRN}[✓]${RST} $*"; }
bad()  { echo -e "${RED}[x]${RST} $*"; }
warn() { echo -e "${YLW}[!]${RST} $*"; }

# ======================
#  ENVIRONMENT
# ======================

export PATH="$(pwd)/$TC_DIR/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="KeiAxiro"
export KBUILD_BUILD_HOST="ubuntu"

# ======================
#  TOOLCHAIN CHECK
# ======================

if ! command -v clang &>/dev/null; then
    bad "Clang tidak ditemukan di PATH!"
    echo "Pastikan $TC_DIR berisi toolchain clang yang valid."
    exit 1
fi

# ======================
#  DEFCONFIG REGEN
# ======================

if [[ $1 == "-r" || $1 == "--regen" ]]; then
    make O=out ARCH=arm64 "$DEFCONFIG" savedefconfig
    cp out/defconfig arch/arm64/configs/"$DEFCONFIG"
    good "Defconfig berhasil diregenerasi."
    exit 0
fi

# ======================
#  BUILD START
# ======================

mkdir -p out
say "Menjalankan defconfig..."
make O=out ARCH=arm64 "$DEFCONFIG"

say "\nMulai kompilasi kernel..."
make -j"$(nproc)" O=out \
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

# ======================
#  POST-BUILD
# ======================

OUT_IMG="out/arch/arm64/boot/Image.gz-dtb"

if [[ -f "$OUT_IMG" ]]; then
    good "Kernel berhasil dikompilasi!"

    # Pastikan AnyKernel3 lokal tersedia
    if [[ ! -d "$AK3_DIR" ]]; then
        bad "Direktori AnyKernel3 tidak ditemukan di $AK3_DIR!"
        echo "Letakkan folder AnyKernel3 di path tersebut, lalu jalankan ulang build."
        exit 1
    fi

    say "Menyiapkan AnyKernel3 lokal..."
    cp "$OUT_IMG" "$AK3_DIR"/Image.gz-dtb

    (
        cd "$AK3_DIR"
        rm -f "../$ZIPNAME"
        zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
    )

    good "Build selesai dalam $((SECONDS / 60))m $((SECONDS % 60))s"
    say "Output: $ZIPNAME"

else
    bad "Build gagal! Cek log di build.log."
    exit 1
fi