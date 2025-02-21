# qBittorrent, OpenVPN and WireGuard, qbittorrentvpn
FROM debian:sid-slim

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /downloads /config/qBittorrent /etc/openvpn /etc/qbittorrent

# Install boost
RUN apt update \
    && apt upgrade -y  \
    && apt install -y --no-install-recommends \
    curl \
    ca-certificates \
    g++ \
    libxml2-utils \
    ninja-build \
    && BOOST_VERSION=1.86.0 \
    && BOOST_VERSION_US=$(echo ${BOOST_VERSION} | tr '.' '_') \
    && curl -o /opt/boost_${BOOST_VERSION_US}.tar.gz -L https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_US}.tar.gz \
    && tar -xzf /opt/boost_${BOOST_VERSION_US}.tar.gz -C /opt \
    && cd /opt/boost_${BOOST_VERSION_US} \
    && ./bootstrap.sh --prefix=/usr \
    && ./b2 --prefix=/usr install \
    && cd /opt \
    && rm -rf /opt/* \
    && apt -y purge \
    curl \
    ca-certificates \
    g++ \
    libxml2-utils \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Install Ninja
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    unzip \
    && NINJA_ASSETS=$(curl -sX GET "https://api.github.com/repos/ninja-build/ninja/releases" | jq '.[] | select(.prerelease==false) | .assets_url' | head -n 1 | tr -d '"') \
    && NINJA_DOWNLOAD_URL=$(curl -sX GET ${NINJA_ASSETS} | jq '.[] | select(.name | match("ninja-linux.zip";"i")) .browser_download_url' | tr -d '"') \
    && curl -o /opt/ninja-linux.zip -L ${NINJA_DOWNLOAD_URL} \
    && unzip /opt/ninja-linux.zip -d /opt \
    && mv /opt/ninja /usr/local/bin/ninja \
    && chmod +x /usr/local/bin/ninja \
    && rm -rf /opt/* \
    && apt purge -y \
    ca-certificates \
    curl \
    jq \
    unzip \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Install cmake
RUN apt update \
    && apt upgrade -y \
    && apt install -y  --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    && CMAKE_ASSETS=$(curl -sX GET "https://api.github.com/repos/Kitware/CMake/releases" | jq '.[] | select(.prerelease==false) | .assets_url' | head -n 1 | tr -d '"') \
    && CMAKE_DOWNLOAD_URL=$(curl -sX GET ${CMAKE_ASSETS} | jq '.[] | select(.name | match("Linux-x86_64.sh";"i")) .browser_download_url' | tr -d '"') \
    && curl -o /opt/cmake.sh -L ${CMAKE_DOWNLOAD_URL} \
    && chmod +x /opt/cmake.sh \
    && /bin/bash /opt/cmake.sh --skip-license --prefix=/usr \
    && rm -rf /opt/* \
    && apt purge -y \
    ca-certificates \
    curl \
    jq \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Compile and install libtorrent-rasterbar
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    jq \
    libssl-dev \
    && LIBTORRENT_ASSETS=$(curl -sX GET "https://api.github.com/repos/arvidn/libtorrent/releases" | jq '.[] | select(.prerelease==false) | select(.target_commitish=="RC_1_2") | .assets_url' | head -n 1 | tr -d '"') \
    && LIBTORRENT_DOWNLOAD_URL=$(curl -sX GET ${LIBTORRENT_ASSETS} | jq '.[0] .browser_download_url' | tr -d '"') \
    && LIBTORRENT_NAME=$(curl -sX GET ${LIBTORRENT_ASSETS} | jq '.[0] .name' | tr -d '"') \
    && curl -o /opt/${LIBTORRENT_NAME} -L ${LIBTORRENT_DOWNLOAD_URL} \
    && tar -xzf /opt/${LIBTORRENT_NAME} \
    && rm /opt/${LIBTORRENT_NAME} \
    && cd /opt/libtorrent-rasterbar* \
    && cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build \
    && cd /opt \
    && rm -rf /opt/* \
    && apt purge -y \
    build-essential \
    ca-certificates \
    curl \
    jq \
    libssl-dev \
    && apt-get clean \
    && apt --purge autoremove -y  \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Compile and install qBittorrent
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    jq \
    libssl-dev \
    pkg-config \
    qt6-base-dev \
    qt6-base-private-dev \
    qt6-tools-dev \
    qt6-tools-dev-tools \
    libgcrypt20-dev \
    qt6-l10n-tools \
    zlib1g-dev \
    && QBITTORRENT_RELEASE=$(curl -sX GET "https://api.github.com/repos/qBittorrent/qBittorrent/tags" | jq '.[] | select(.name | index ("alpha") | not) | select(.name | index ("beta") | not) | select(.name | index ("rc") | not) | .name' | head -n 1 | tr -d '"') \
    && curl -o /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz -L "https://github.com/qbittorrent/qBittorrent/archive/${QBITTORRENT_RELEASE}.tar.gz" \
    && tar -xzf /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz \
    && rm /opt/qBittorrent-${QBITTORRENT_RELEASE}.tar.gz \
    && cd /opt/qBittorrent-${QBITTORRENT_RELEASE} \
    && cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DGUI=OFF -DCMAKE_CXX_STANDARD=17 \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build \
    && cd /opt \
    && rm -rf /opt/* \
    && apt purge -y \
    build-essential \
    ca-certificates \
    curl \
    git \
    jq \
    libssl-dev \
    pkg-config \
    qt6-base-dev \
    qt6-base-private-dev \
    qt6-tools-dev \
    qt6-tools-dev-tools \
    libgcrypt20-dev \
    qt6-l10n-tools \
    zlib1g-dev \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Install WireGuard and some other dependencies some of the scripts in the container rely on.
RUN echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list \
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable \
    && apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    dos2unix \
    inetutils-ping \
    ipcalc \
    iptables \
    kmod \
    libqt6network6 \
    libqt6xml6 \
    libqt6sql6 \
    libssl-dev \
    moreutils \
    net-tools \
    openresolv \
    openvpn \
    procps \
    wireguard-tools \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Install (un)compressing tools like unrar, 7z, unzip and zip
RUN echo "deb http://deb.debian.org/debian/ bullseye non-free" > /etc/apt/sources.list.d/non-free-unrar.list \
    && printf 'Package: *\nPin: release a=non-free\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-non-free \
    && apt update \
    && apt -y upgrade \
    && apt -y install --no-install-recommends \
    unrar \
    p7zip-full \
    unzip \
    zip \
    iproute2 \
    && apt-get clean \
    && apt --purge autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Remove src_valid_mark from wg-quick
RUN sed -i /net\.ipv4\.conf\.all\.src_valid_mark/d `which wg-quick`

VOLUME /config /downloads

ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/

RUN chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh

EXPOSE 8080
EXPOSE 8999
EXPOSE 8999/udp
CMD ["/bin/bash", "/etc/openvpn/start.sh"]
