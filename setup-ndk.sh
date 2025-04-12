#!/bin/bash

# Ganti versi kalau perlu
NDK_VERSION="r27c"
NDK_ZIP="android-ndk-${NDK_VERSION}-linux.zip"
NDK_URL="https://dl.google.com/android/repository/${NDK_ZIP}"
NDK_DIR="$HOME/android-ndk-${NDK_VERSION}"

# Download NDK
echo "Downloading Android NDK $NDK_VERSION..."
wget -c "$NDK_URL" -O "$NDK_ZIP"

# Ekstrak
echo "Extracting..."
unzip -q "$NDK_ZIP" -d "$HOME"

# Tambahkan ke PATH (sementara untuk session ini)
export PATH="$NDK_DIR:$PATH"

# Tambahkan ke PATH permanen (bashrc)
if ! grep -q "android-ndk-${NDK_VERSION}" "$HOME/.bashrc"; then
  echo "export PATH=\"$NDK_DIR:\$PATH\"" >> "$HOME/.bashrc"
  echo "Added to .bashrc"
fi

# Cek versi
echo "Verifying..."
ndk-build --version
