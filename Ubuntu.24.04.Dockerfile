FROM ubuntu:24.04
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-c"]

ARG TARGETARCH
ARG SWIFT_VERSION='6.3'
ARG SWIFT_NIGHTLY='SNAPSHOT-2026-01-16-a'
ARG SWIFT_WASM_SDK_CHECKSUM='6054e019dce24a3ed875584cffa0621eaf2f6200f6366270b39768347addc133'
ARG UBUNTU_VERSION='ubuntu24.04'

ENV SWIFT_INSTALLATION="/usr/local/swift"
ENV PATH="$PATH:$SWIFT_INSTALLATION/usr/bin"

# Squash the following RUN commands into a single command to reduce image size
RUN <<EOF

apt update
apt -y install curl

if [ "$TARGETARCH" = "arm64" ]; then
    echo "Configuring for aarch64..."
    SWIFT_PLATFORM="aarch64"
    SWIFT_PLATFORM_SUFFIX="-aarch64"
else
    echo "Configuring for x86_64..."
    SWIFT_PLATFORM="x86_64"
    SWIFT_PLATFORM_SUFFIX=""
fi

# Note: The Docker CLI does not print the correct URL to the console, but the actual
# interpolated string passed to `curl` is correct.
curl "https://download.swift.org/\
swift-${SWIFT_VERSION}-branch/\
${UBUNTU_VERSION//[.]/}${SWIFT_PLATFORM_SUFFIX}/\
swift-${SWIFT_VERSION}-DEVELOPMENT-${SWIFT_NIGHTLY}/\
swift-${SWIFT_VERSION}-DEVELOPMENT-${SWIFT_NIGHTLY}-${UBUNTU_VERSION}${SWIFT_PLATFORM_SUFFIX}.tar.gz" \
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

# Unpack the Swift toolchain to /usr/local/swift
mkdir -p "$SWIFT_INSTALLATION"
tar --strip-components=1 -xf toolchain.tar.gz -C "$SWIFT_INSTALLATION"
rm toolchain.tar.gz

# need to install a newer nodejs than is available by default
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt update
apt -y install \
    nodejs \
    sudo \
    passwd \
    libjemalloc2 \
    libjemalloc-dev \
    libsqlite3-dev \
    libncurses-dev \
    liblz4-dev \
    binaryen \
    gh \
    jq \
    imagemagick

# clean up cached files
rm -rf /var/lib/apt/lists/*
node -v

EOF

WORKDIR /home/ubuntu

RUN passwd -d ubuntu
RUN usermod -aG sudo ubuntu

ENV SWIFT_WASM_SDK="${SWIFT_VERSION}-${SWIFT_NIGHTLY}-wasm32-unknown-wasip1-threads"
ENV SWIFT_WASM_SDK_PATH='/usr/local/share/swift'

RUN swift sdk install \
    https://github.com/swiftwasm/swift/releases/download/swift-wasm-${SWIFT_VERSION}-${SWIFT_NIGHTLY}/swift-wasm-${SWIFT_VERSION}-${SWIFT_NIGHTLY}-wasm32-unknown-wasip1-threads.artifactbundle.zip \
    --checksum ${SWIFT_WASM_SDK_CHECKSUM} \
    --swift-sdks-path "$SWIFT_WASM_SDK_PATH"

# Switch back to the standard user for default execution
USER ubuntu
ENV HOME /home/ubuntu
CMD ["sleep", "infinity"]
