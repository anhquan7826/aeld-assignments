#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_stable
FINDER_APP_DIR=$(realpath $(dirname $0))
export ARCH=arm64
export CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # DONE: Add your kernel build steps here
    # clean all
    make  mrproper
    # generate new config
    make defconfig
    # build all
    make -j$(nproc) all dtbs
fi

echo "Adding the Image in outdir"
cp "$OUTDIR/linux-stable/arch/$ARCH/boot/Image" "$OUTDIR/Image"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf ${OUTDIR}/rootfs
fi

# DONE: Create necessary base directories
mkdir "$OUTDIR/rootfs"
cd "$OUTDIR/rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    # git://busybox.net/busybox.git died, switch to mirror
    git clone https://github.com/mirror/busybox.git --depth 1 --branch ${BUSYBOX_VERSION}
    cd busybox
    # TODO:  Configure busybox
else
    cd busybox
fi

# DONE: Make and install busybox
make distclean
make defconfig
make
make CONFIG_PREFIX="$OUTDIR/rootfs" install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a "$OUTDIR/rootfs/bin/busybox" | grep "program interpreter"
${CROSS_COMPILE}readelf -a "$OUTDIR/rootfs/bin/busybox" | grep "Shared library"

# DONE: Add library dependencies to rootfs
SYSROOT="$(${CROSS_COMPILE}gcc -print-sysroot)"
echo "SYSROOT: $SYSROOT"
cp "$SYSROOT/lib/ld-linux-aarch64.so.1" "$OUTDIR/rootfs/lib/"
cp "$SYSROOT/lib64/libm.so.6" "$OUTDIR/rootfs/lib64/"
cp "$SYSROOT/lib64/libresolv.so.2" "$OUTDIR/rootfs/lib64/"
cp "$SYSROOT/lib64/libc.so.6" "$OUTDIR/rootfs/lib64/"

# DONE: Make device nodes
sudo mknod -m 666 "$OUTDIR/rootfs/dev/null" c 1 3
sudo mknod -m 666 "$OUTDIR/rootfs/dev/console" c 5 1

# DONE: Clean and build the writer utility
cd "$FINDER_APP_DIR"
make clean
make

# DONE: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer "$OUTDIR/rootfs/home"
cp finder.sh "$OUTDIR/rootfs/home"
cp -r conf/ "$OUTDIR/rootfs/home"
cp finder-test.sh "$OUTDIR/rootfs/home"
cp autorun-qemu.sh "$OUTDIR/rootfs/home"

# TODO: Chown the root directory
# sudo chown -R root:root "$OUTDIR/rootfs"

# DONE: Create initramfs.cpio.gz
cd "$OUTDIR/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio