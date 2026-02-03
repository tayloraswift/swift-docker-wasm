FROM ubuntu:24.04
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

ARG SWIFT_VERSION='6.3'
ARG SWIFT_NIGHTLY
ARG UBUNTU_VERSION='ubuntu24.04'

WORKDIR /home/ubuntu

# Squash the following RUN commands into a single command to reduce image size
RUN <<EOF

apt update
apt -y install curl

# Note: The Docker CLI does not print the correct URL to the console, but the actual
# interpolated string passed to `curl` is correct.
curl "https://download.swift.org/\
swift-${SWIFT_VERSION}-branch/\
${UBUNTU_VERSION//[.]/}/\
swift-${SWIFT_VERSION}-DEVELOPMENT-${SWIFT_NIGHTLY}/\
swift-${SWIFT_VERSION}-DEVELOPMENT-${SWIFT_NIGHTLY}-${UBUNTU_VERSION}.tar.gz" \
    -o toolchain.tar.gz

apt -y dist-upgrade

# Install dependencies of the Swift toolchain
apt update
apt -y install \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-13-dev \
    libncurses-dev \
    libsqlite3-0 \
    libstdc++-13-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev

# Install dependencies needed for AArch64 cross-compilation. For some reason, `apt` cannot
# resolve the dependencies if we install them all at once.
apt -y install gcc-aarch64-linux-gnu
apt -y install libstdc++-13-dev-arm64-cross
apt -y install g++-multilib

# Unpack the Swift toolchain for x86_64
mkdir -p /home/ubuntu/x86_64/${SWIFT_VERSION}
cd /home/ubuntu/x86_64/${SWIFT_VERSION}

tar --strip-components=1 -xf /home/ubuntu/toolchain.tar.gz
rm /home/ubuntu/toolchain.tar.gz

EOF

WORKDIR /home/ubuntu

# Create symbolic links to the Swift toolchains, to make it easier to reference them
RUN ln -s /home/ubuntu/x86_64/${SWIFT_VERSION} /home/ubuntu/x86_64/swift

RUN apt install -y \
    sudo \
    passwd \
    libjemalloc2 \
    libjemalloc-dev \
    libsqlite3-dev \
    libncurses-dev \
    liblz4-dev \
    binaryen \
    nodejs \
    npm \
    gh \
    jq

RUN passwd -d ubuntu
RUN usermod -aG sudo ubuntu

RUN apt update
RUN apt dist-upgrade
RUN apt install -y \
    imagemagick

USER ubuntu

ENV PATH="$PATH:/home/ubuntu/x86_64/swift/usr/bin"
ENV SWIFT_INSTALLATION="/home/ubuntu/x86_64/swift/usr"
ENV SWIFT_WASM_SDK='$SWIFT_VERSION-$SWIFT_NIGHTLY-wasm32-unknown-wasip1-threads'

RUN swift sdk install https://github.com/swiftwasm/swift/releases/download/swift-wasm-${SWIFT_VERSION}-${SWIFT_NIGHTLY}/swift-wasm-${SWIFT_VERSION}-${SWIFT_NIGHTLY}-wasm32-unknown-wasip1-threads.artifactbundle.zip --checksum 6054e019dce24a3ed875584cffa0621eaf2f6200f6366270b39768347addc133
CMD ["sleep", "infinity"]
