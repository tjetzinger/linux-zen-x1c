# Maintainer: Custom build based on linux-zen
# Original: Jan Alexander Steffens (heftig) <heftig@archlinux.org>

pkgbase=linux-zen-x1c
pkgver=6.18.2.zen2
pkgrel=1
pkgdesc='Linux ZEN - Custom build for ThinkPad X1 Carbon Gen 11'
url='https://github.com/zen-kernel/zen-kernel'
arch=(x86_64)
license=(GPL-2.0-only)
makedepends=(
  bc
  cpio
  gettext
  libelf
  pahole
  perl
  python
  rust
  rust-bindgen
  rust-src
  tar
  xz
)
options=(
  !debug
  !strip
)
_srcname=linux-${pkgver%.*}
_srctag=v${pkgver%.*}-${pkgver##*.}
source=(
  https://cdn.kernel.org/pub/linux/kernel/v${pkgver%%.*}.x/${_srcname}.tar.{xz,sign}
  $url/releases/download/$_srctag/linux-$_srctag.patch.zst{,.sig}
  config  # the main kernel config file
)
validpgpkeys=(
  ABAF11C65A2970B130ABE3C479BE3E4300411886  # Linus Torvalds
  647F28654894E3BD457199BE38DBBDC86092693E  # Greg Kroah-Hartman
  83BC8889351B5DEBBB68416EB8AC08600F108CDF  # Jan Alexander Steffens (heftig)
)
# https://www.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc
sha256sums=('558c6bbab749492b34f99827fe807b0039a744693c21d3a7e03b3a48edaab96a'
            'SKIP'
            '7cfe4a23b967ec8a595f5f5739bb30aa075e6c152b9f383e1c2dfd6cdff7b367'
            'SKIP'
            '09769a51ef62e72336d36df52a8e43735a13c510499a071007b3c59a916f2546')
b2sums=('2e5cae5fe963cf25344ccfe9426d2edab2583b1bb206f6551d60177777595d4c19200e5e3c35ca41b574d25e8fa49013ea086efe05078e7ec2203c77ea420d51'
        'SKIP'
        'd390c7b9722b0fe5e10e56f7f00607d80e9a63329b1b0711e998529e5cb3bfa930c042331100fe1d847e3d1a23b3ab417e85011bb92d9913bc6a0308bc3a3b7b'
        'SKIP'
        '4f90aa8cfbb74b589543aa270fe38d8790e8ab367ff190f10400d6500330d176b0cfb31c60677690fef580430569e4f21d72e29ca96488159532466d8b18ac19')

export KBUILD_BUILD_HOST=archlinux
export KBUILD_BUILD_USER=$pkgbase
export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"

prepare() {
  cd $_srcname

  echo "Setting version..."
  echo "-$pkgrel" > localversion.10-pkgrel
  echo "${pkgbase#linux}" > localversion.20-pkgname

  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    src="${src%.zst}"
    [[ $src = *.patch ]] || continue
    echo "Applying patch $src..."
    patch -Np1 < "../$src"
  done

  echo "Setting config..."
  cp ../config .config
  make olddefconfig

  # === LOCALMODCONFIG ===
  # Reduce kernel to only currently loaded modules
  echo "Running localmodconfig with captured modules..."
  if [[ -f /tmp/modules.lst ]]; then
    make LSMOD=/tmp/modules.lst localmodconfig
  else
    echo "WARNING: /tmp/modules.lst not found, skipping localmodconfig"
  fi

  # === HARDWARE-SPECIFIC CONFIG ===
  # Intel Raptor Lake - use native CPU optimization
  echo "Applying hardware-specific configuration..."
  echo "Enabling native CPU optimization (-march=native for Raptor Lake)..."
  scripts/config --enable CONFIG_X86_NATIVE_CPU

  # Timer and preemption (zen defaults are good, but ensure they're set)
  scripts/config --set-val CONFIG_HZ 1000
  scripts/config --enable CONFIG_HZ_1000
  scripts/config --enable CONFIG_PREEMPT

  # Kernel compression
  scripts/config --enable CONFIG_KERNEL_ZSTD

  # Intel power management
  scripts/config --enable CONFIG_X86_INTEL_PSTATE
  scripts/config --module CONFIG_INTEL_RAPL

  # Intel graphics (ensure enabled after localmodconfig)
  scripts/config --module CONFIG_DRM_XE
  scripts/config --module CONFIG_DRM_I915

  # Audio - Intel SOF
  scripts/config --module CONFIG_SND_SOC_SOF_INTEL_TGL

  # WiFi/Bluetooth
  scripts/config --module CONFIG_IWLMVM
  scripts/config --module CONFIG_BT_HCIBTUSB

  # Storage essentials (critical for boot)
  scripts/config --enable CONFIG_BLK_DEV_NVME
  scripts/config --module CONFIG_DM_CRYPT
  scripts/config --enable CONFIG_BTRFS_FS

  # ThinkPad
  scripts/config --module CONFIG_THINKPAD_ACPI

  # Virtualization
  scripts/config --module CONFIG_KVM_INTEL

  # Disable AMD (not needed)
  scripts/config --disable CONFIG_CPU_SUP_AMD
  scripts/config --disable CONFIG_MICROCODE_AMD
  scripts/config --disable CONFIG_DRM_AMDGPU
  scripts/config --disable CONFIG_KVM_AMD

  # Refresh config after changes
  make olddefconfig

  # === MENUCONFIG ===
  # Interactive configuration - user can make final adjustments
  echo ""
  echo "=========================================="
  echo "  MENUCONFIG - Make your adjustments"
  echo "=========================================="
  echo "Key locations:"
  echo "  - Processor type: General setup -> Processor family"
  echo "  - Timer: General setup -> Preemption Model / Timer frequency"
  echo "  - Power: Power management"
  echo "  - Drivers: Device Drivers"
  echo ""
  echo "Press Enter to continue to menuconfig..."
  read -r
  make menuconfig

  make -s kernelrelease > version
  echo "Prepared $pkgbase version $(<version)"
}

build() {
  cd $_srcname
  make all
  make -C tools/bpf/bpftool vmlinux.h feature-clang-bpf-co-re=1
}

_package() {
  pkgdesc="The $pkgdesc kernel and modules"
  depends=(
    coreutils
    initramfs
    kmod
  )
  optdepends=(
    'linux-firmware: firmware images needed for some devices'
    'scx-scheds: to use sched-ext schedulers'
    'wireless-regdb: to set the correct wireless channels of your country'
  )
  provides=(
    KSMBD-MODULE
    NTSYNC-MODULE
    VHBA-MODULE
    VIRTUALBOX-GUEST-MODULES
    WIREGUARD-MODULE
  )
  replaces=(
  )

  cd $_srcname
  local modulesdir="$pkgdir/usr/lib/modules/$(<version)"

  echo "Installing boot image..."
  # systemd expects to find the kernel here to allow hibernation
  # https://github.com/systemd/systemd/commit/edda44605f06a41fb86b7ab8128dcf99161d2344
  install -Dm644 "$(make -s image_name)" "$modulesdir/vmlinuz"

  # Used by mkinitcpio to name the kernel
  echo "$pkgbase" | install -Dm644 /dev/stdin "$modulesdir/pkgbase"

  echo "Installing modules..."
  ZSTD_CLEVEL=19 make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 \
    DEPMOD=/doesnt/exist modules_install  # Suppress depmod

  # remove build link
  rm "$modulesdir"/build
}

_package-headers() {
  pkgdesc="Headers and scripts for building modules for the $pkgdesc kernel"
  depends=(pahole)

  cd $_srcname
  local builddir="$pkgdir/usr/lib/modules/$(<version)/build"

  echo "Installing build files..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
    localversion.* version vmlinux tools/bpf/bpftool/vmlinux.h
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/x86" -m644 arch/x86/Makefile
  cp -t "$builddir" -a scripts
  ln -srt "$builddir" "$builddir/scripts/gdb/vmlinux-gdb.py"

  # required when STACK_VALIDATION is enabled
  install -Dt "$builddir/tools/objtool" tools/objtool/objtool

  # required when DEBUG_INFO_BTF_MODULES is enabled
  install -Dt "$builddir/tools/bpf/resolve_btfids" tools/bpf/resolve_btfids/resolve_btfids

  echo "Installing headers..."
  cp -t "$builddir" -a include
  cp -t "$builddir/arch/x86" -a arch/x86/include
  install -Dt "$builddir/arch/x86/kernel" -m644 arch/x86/kernel/asm-offsets.s

  install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
  install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h

  # https://bugs.archlinux.org/task/13146
  install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h

  # https://bugs.archlinux.org/task/20402
  install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
  install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
  install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h

  # https://bugs.archlinux.org/task/71392
  install -Dt "$builddir/drivers/iio/common/hid-sensors" -m644 drivers/iio/common/hid-sensors/*.h

  echo "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

  echo "Installing Rust files..."
  install -Dt "$builddir/rust" -m644 rust/*.rmeta
  install -Dt "$builddir/rust" rust/*.so

  echo "Installing unstripped VDSO..."
  make INSTALL_MOD_PATH="$pkgdir/usr" vdso_install \
    link=  # Suppress build-id symlinks

  echo "Removing unneeded architectures..."
  local arch
  for arch in "$builddir"/arch/*/; do
    [[ $arch = */x86/ ]] && continue
    echo "Removing $(basename "$arch")"
    rm -r "$arch"
  done

  echo "Removing documentation..."
  rm -r "$builddir/Documentation"

  echo "Removing broken symlinks..."
  find -L "$builddir" -type l -printf 'Removing %P\n' -delete

  echo "Removing loose objects..."
  find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete

  echo "Stripping build tools..."
  local file
  while read -rd '' file; do
    case "$(file -Sib "$file")" in
      application/x-sharedlib\;*)      # Libraries (.so)
        strip -v $STRIP_SHARED "$file" ;;
      application/x-archive\;*)        # Libraries (.a)
        strip -v $STRIP_STATIC "$file" ;;
      application/x-executable\;*)     # Binaries
        strip -v $STRIP_BINARIES "$file" ;;
      application/x-pie-executable\;*) # Relocatable binaries
        strip -v $STRIP_SHARED "$file" ;;
    esac
  done < <(find "$builddir" -type f -perm -u+x ! -name vmlinux -print0)

  echo "Stripping vmlinux..."
  strip -v $STRIP_STATIC "$builddir/vmlinux"

  echo "Adding symlink..."
  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"
}

# Only build kernel and headers (skip docs)
pkgname=(
  "$pkgbase"
  "$pkgbase-headers"
)
for _p in "${pkgname[@]}"; do
  eval "package_$_p() {
    $(declare -f "_package${_p#$pkgbase}")
    _package${_p#$pkgbase}
  }"
done

# vim:set ts=8 sts=2 sw=2 et:
