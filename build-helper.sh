#!/bin/bash -e

# This script is executed within the container as root.  It assumes
# that source code with debian packaging files can be found at
# /source-ro and that resulting packages are written to /output after
# succesful build.  These directories are mounted as docker volumes to
# allow files to be exchanged between the host and the container.

# Install extra dependencies that were provided for the build (if any)
#   Note: dpkg can fail due to dependencies, ignore errors, and use
#   apt-get to install those afterwards
[[ -d /dependencies ]] && dpkg -i /dependencies/*.deb || apt-get -f install -y --no-install-recommends

# Make read-write copy of source code
mkdir -p /build
cp -a /source-ro /build/source
cd /build/source


# Cross build?
if [ -n "${CROSS_TRIPLE}" ]; then

    case "${CROSS_TRIPLE}" in
        i686-linux-gnu)
            CROSS_ARGS="--host-arch i386"
            ;;
        arm-linux-gnueabihf)
            CROSS_ARGS="--host-arch armhf"
            ;;
        aarch64-linux-gnu)
            CROSS_ARGS="--host-arch arm64"
            ;;
        mipsel-linux-gnu)
            CROSS_ARGS="--host-arch mipsel"
            ;;
        mips64el-linux-gnuabi64)
            CROSS_ARGS="--host-arch mips64el"
            ;;
        powerpc64le-linux-gnu)
            CROSS_ARGS="--host-arch ppc64el"
            ;;
        *)
            echo "${CROSS_TRIPLE} not yet implemented." && exit 1 ;;
    esac
fi

# Install build dependencies
apt-get update
printf "Installing dependencies "
mk-build-deps $CROSS_ARGS -ir -t "apt-get -o Debug::pkgProblemResolver=yes -y --no-install-recommends" | while read LINE; do
    printf "."
done
printf "\n"

# Build packages
dpkg-buildpackage -b -uc -us $CROSS_ARGS

# Copy packages to output dir with user's permissions
chown -R $USER:$GROUP /build
cp -a /build/*.deb /output/
ls -l /output
