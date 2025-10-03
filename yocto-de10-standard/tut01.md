# Tutorial: Building DE10-Standard Yocto Linux System

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [System Requirements](#system-requirements)
4. [Quick Start (Automated)](#quick-start-automated)
5. [Manual Step-by-Step Build](#manual-step-by-step-build)
6. [Understanding the Layers](#understanding-the-layers)
7. [Customization Guide](#customization-guide)
8. [Flashing and Testing](#flashing-and-testing)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Topics](#advanced-topics)

## Introduction

This tutorial guides you through building a complete Linux system for the DE10-Standard development board using the Yocto Project. The DE10-Standard features an Intel Cyclone V SoC with dual-core ARM Cortex-A9 processor and FPGA fabric.

**What you'll build:**
- Bootable Linux image for DE10-Standard
- Root filesystem with systemd, SSH, and development tools
- Bootloader (U-Boot) configuration
- Device tree for proper hardware support
- WIC image for easy SD card deployment

## Prerequisites

### Knowledge Requirements
- Basic Linux command line experience
- Understanding of embedded Linux concepts
- Familiarity with Git version control
- Basic knowledge of Yocto Project (recommended but not required)

### Hardware Requirements
- DE10-Standard development board
- MicroSD card (8GB minimum, 16GB+ recommended)
- USB-to-UART cable for serial console
- Ethernet cable for network connectivity
- Power supply for DE10-Standard

## System Requirements

### Host System
- **OS**: Ubuntu 20.04 LTS or later (recommended)
- **CPU**: Multi-core x86_64 processor (4+ cores recommended)
- **RAM**: 8GB minimum, 16GB+ recommended
- **Storage**: 100GB+ free space (builds can be 50-80GB)
- **Network**: Reliable internet connection for downloading sources

### Software Dependencies
```bash
sudo apt update
sudo apt install -y \\
    git build-essential python3 python3-pip python3-venv \\
    gawk wget diffstat unzip texinfo gcc-multilib \\
    chrpath socat cpio xz-utils debianutils iputils-ping \\
    libegl1-mesa libsdl1.2-dev pylint3 xterm file locales
```

## Quick Start (Automated)

We provide a comprehensive build script that automates the entire process:

### 1. Download and Run Build Script

```bash
# Create workspace directory
mkdir -p ~/de10-yocto-build
cd ~/de10-yocto-build

# Download the build script (if you have it)
# Or create from scratch using the provided script

# Make executable and run
chmod +x build_de10.sh
./build_de10.sh
```

### 2. Script Options

```bash
# Clean build (removes existing build directory)
./build_de10.sh --clean

# Setup only (don't start build)
./build_de10.sh --setup-only

# Show help
./build_de10.sh --help
```

### 3. What the Script Does
1. Checks and installs dependencies
2. Creates workspace directory structure
3. Clones all required Yocto layers with exact commit hashes
4. Applies local customizations
5. Creates DE10-Standard specific layer
6. Configures build environment
7. Starts the build process

**Build Time:** Expect 1-3 hours depending on your system performance.

## Manual Step-by-Step Build

If you prefer to understand each step or need to customize the process:

### Step 1: Create Workspace

```bash
mkdir -p ~/de10-yocto-build
cd ~/de10-yocto-build
```

### Step 2: Clone Yocto Layers

```bash
# 1. Poky (main Yocto repository)
git clone https://git.yoctoproject.org/poky.git
cd poky
git checkout scarthgap
git reset --hard e3ce89324da1e33c17c9180ef846f41d92616254
cd ..

# 2. Meta-OpenEmbedded (additional recipes)
git clone https://github.com/openembedded/meta-openembedded.git
cd meta-openembedded
git checkout scarthgap
git reset --hard e621da947048842109db1b4fd3917a02e0501aa2
cd ..

# 3. Intel FPGA Reference Design layer
git clone https://github.com/altera-opensource/meta-intel-fpga-refdes.git
cd meta-intel-fpga-refdes
git checkout scarthgap
git reset --hard bffc5bc012f1653beb58878b54b44e74b0f27404
cd ..

# 4. Enhanced Intel FPGA layer
git clone https://github.com/robseb/meta-intelfpga.git
cd meta-intelfpga
git checkout a71dba983ec5e1af96bc3556a959fb8d0fe1044e
cd ..
```

### Step 3: Create Custom DE10-Standard Layer

```bash
mkdir -p meta-de10-standard/conf
mkdir -p meta-de10-standard/recipes-bsp/device-tree
mkdir -p meta-de10-standard/recipes-example/example

# Create layer configuration
cat > meta-de10-standard/conf/layer.conf << 'EOF'
BBPATH .= ":${LAYERDIR}"
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \\
            ${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "meta-de10-standard"
BBFILE_PATTERN_meta-de10-standard = "^${LAYERDIR}/"
BBFILE_PRIORITY_meta-de10-standard = "6"

LAYERDEPENDS_meta-de10-standard = "core"
LAYERSERIES_COMPAT_meta-de10-standard = "scarthgap"
EOF
```

### Step 4: Apply Customizations

```bash
# Enhance image formats in meta-intelfpga
sed -i 's/IMAGE_FSTYPES ?= "tar.gz"/IMAGE_FSTYPES ?= "ext4 tar.gz wic wic.gz wic.bmap"/' \\
    meta-intelfpga/conf/machine/include/socfpga.inc

# Add kernel development support option
cat >> meta-intelfpga/recipes-core/images/core-image-minimal.bbappend << 'EOF'

# Add comprehensive kernel development support
# IMAGE_INSTALL:append = " kernel-dev kernel-modules "
EOF
```

### Step 5: Initialize Build Environment

```bash
source poky/oe-init-build-env build
```

You're now in the `build/` directory.

### Step 6: Configure Layers

Edit `conf/bblayers.conf`:

```bash
cat > conf/bblayers.conf << 'EOF'
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \\
  ${TOPDIR}/../poky/meta \\
  ${TOPDIR}/../poky/meta-poky \\
  ${TOPDIR}/../poky/meta-yocto-bsp \\
  ${TOPDIR}/../meta-openembedded/meta-oe \\
  ${TOPDIR}/../meta-openembedded/meta-python \\
  ${TOPDIR}/../meta-openembedded/meta-networking \\
  ${TOPDIR}/../meta-intelfpga \\
  ${TOPDIR}/../meta-de10-standard \\
  "
EOF
```

### Step 7: Configure Build Settings

Add to `conf/local.conf`:

```bash
cat >> conf/local.conf << 'EOF'

# DE10-Standard Configuration
MACHINE = "cyclone5"
DISTRO = "poky"

# Enhanced image formats for DE10-Standard
IMAGE_FSTYPES += "wic wic.gz wic.bmap"

# Enable systemd and modern features
DISTRO_FEATURES:append = " systemd usrmerge"
VIRTUAL-RUNTIME_init_manager = "systemd"

# Build optimization
BB_NUMBER_THREADS ?= "${@oe.utils.cpu_count()}"
PARALLEL_MAKE ?= "-j ${@oe.utils.cpu_count()}"

# Development features
EXTRA_IMAGE_FEATURES ?= "debug-tweaks ssh-server-openssh package-management"
LICENSE_FLAGS_ACCEPTED = "commercial"
EOF
```

### Step 8: Start Build

```bash
bitbake core-image-minimal
```

This process will take 1-3 hours.

## Understanding the Layers

### Core Layers Function

| Layer | Purpose | Key Components |
|-------|---------|----------------|
| **poky/meta** | Core Yocto functionality | Base recipes, classes, build system |
| **poky/meta-poky** | Poky distribution config | Distribution policies, toolchain |
| **poky/meta-yocto-bsp** | BSP recipes | Board support packages |
| **meta-oe** | Extended recipes | Additional software packages |
| **meta-python** | Python support | Python libraries and tools |
| **meta-networking** | Network tools | Network utilities and daemons |
| **meta-intel-fpga-refdes** | Intel FPGA support | Official Intel FPGA recipes |
| **meta-intelfpga** | Enhanced FPGA support | Additional tools and configurations |
| **meta-de10-standard** | Board-specific | DE10-Standard customizations |

### Layer Dependencies

```
meta-de10-standard
├── meta-intelfpga
│   └── meta-intel-fpga-refdes
│       └── meta-oe
│           └── core (meta)
└── meta-python
    └── meta-oe
```

## Customization Guide

### Adding Software Packages

Edit `conf/local.conf` to add packages to the image:

```bash
# Add packages to all images
IMAGE_INSTALL:append = " packagename1 packagename2"

# Add to specific image
CORE_IMAGE_EXTRA_INSTALL += "vim nano htop"
```

### Custom Recipes

Create recipes in `meta-de10-standard/recipes-*`:

```bash
# Example application recipe
mkdir -p meta-de10-standard/recipes-apps/myapp
cat > meta-de10-standard/recipes-apps/myapp/myapp_1.0.bb << 'EOF'
SUMMARY = "My custom application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = "file://myapp.c"

do_compile() {
    ${CC} ${WORKDIR}/myapp.c -o myapp
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 myapp ${D}${bindir}
}
EOF
```

### Device Tree Customization

Add device tree modifications in `meta-de10-standard/recipes-bsp/device-tree/`.

### Kernel Configuration

To modify kernel configuration:

```bash
# Add to local.conf
KERNEL_FEATURES:append = " features/debug/debug-kernel.scc"

# Or create custom kernel configuration
```

## Flashing and Testing

### Generated Files Location

After successful build, images are in:
```
build/tmp/deploy/images/cyclone5/
```

Key files:
- `core-image-minimal-cyclone5.wic` - Complete SD card image
- `core-image-minimal-cyclone5.wic.gz` - Compressed image
- `core-image-minimal-cyclone5.wic.bmap` - Block map for fast flashing
- `core-image-minimal-cyclone5.ext4` - Root filesystem only

### Flashing to SD Card

#### Method 1: Using dd

```bash
# Find your SD card device (be careful!)
lsblk

# Flash the image (replace /dev/sdX with your SD card)
sudo dd if=core-image-minimal-cyclone5.wic of=/dev/sdX bs=1M status=progress conv=fsync

# Or use compressed image
zcat core-image-minimal-cyclone5.wic.gz | sudo dd of=/dev/sdX bs=1M status=progress conv=fsync
```

#### Method 2: Using bmaptool (Faster)

```bash
# Install bmaptool
sudo apt install bmap-tools

# Flash with block map (much faster)
sudo bmaptool copy core-image-minimal-cyclone5.wic.gz /dev/sdX
```

### First Boot Setup

1. **Insert SD card** into DE10-Standard
2. **Connect UART cable** (115200 baud, 8N1)
3. **Connect Ethernet** cable
4. **Power on** the board
5. **Monitor boot** via serial console

Default login:
- Username: `root`
- Password: (none - just press Enter)

### Testing Basic Functionality

```bash
# Check system info
uname -a
cat /proc/cpuinfo
cat /proc/meminfo

# Test network
ip addr show
ping google.com

# Test SSH (from another machine)
ssh root@<board-ip>

# Check systemd services
systemctl status
journalctl -f
```

## Troubleshooting

### Common Build Issues

#### 1. Disk Space Issues
```bash
# Clean temporary files
bitbake -c cleanall core-image-minimal

# Or clean specific package
bitbake -c clean package-name
```

#### 2. Network Issues During Build
```bash
# Check downloads directory
ls -la downloads/

# Resume build
bitbake core-image-minimal
```

#### 3. Layer Configuration Issues
```bash
# Verify layer paths
bitbake-layers show-layers

# Check for missing dependencies
bitbake-layers show-cross-depends
```

### Runtime Issues

#### 1. Board Won't Boot
- Check SD card partitioning: `fdisk -l /dev/sdX`
- Verify U-Boot installation
- Check serial console output

#### 2. Network Not Working
- Check Ethernet cable
- Verify device tree configuration
- Check systemd network services

#### 3. SSH Not Accessible
- Verify openssh service: `systemctl status sshd`
- Check firewall settings
- Confirm network connectivity

### Debug Build Issues

```bash
# Verbose build output
bitbake -v core-image-minimal

# Show build dependencies
bitbake -g core-image-minimal

# Check specific recipe
bitbake -e package-name | grep ^WORKDIR
```

## Advanced Topics

### Performance Optimization

#### Build Performance
```bash
# Optimize for your system (add to local.conf)
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"

# Use shared state cache
SSTATE_DIR = "${TOPDIR}/../sstate-cache"

# Use download cache
DL_DIR = "${TOPDIR}/../downloads"
```

#### Runtime Performance
```bash
# Enable specific CPU optimizations
DEFAULTTUNE = "cortexa9thf-neon"

# Optimize package management
PACKAGE_CLASSES = "package_rpm"

# Enable distro features
DISTRO_FEATURES:append = " pam systemd usrmerge"
```

### Custom Image Types

Create custom image recipe:

```bash
mkdir -p meta-de10-standard/recipes-core/images
cat > meta-de10-standard/recipes-core/images/de10-dev-image.bb << 'EOF'
require recipes-core/images/core-image-minimal.bb

SUMMARY = "DE10-Standard development image"

IMAGE_INSTALL += " \\
    vim nano htop \\
    python3 python3-pip \\
    gcc g++ make cmake \\
    git openssh-sftp-server \\
    "

IMAGE_FEATURES += "package-management"
EOF
```

### SDK Generation

Build SDK for cross-development:

```bash
# Build SDK
bitbake core-image-minimal -c populate_sdk

# Install SDK (adjust path)
./tmp/deploy/sdk/poky-glibc-x86_64-core-image-minimal-cortexa9t2hf-neon-cyclone5-toolchain-*.sh

# Use SDK
source /opt/poky/*/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi
```

### FPGA Integration

For FPGA development:

1. Add FPGA tools to image
2. Include device tree overlays
3. Configure FPGA manager
4. Add custom drivers

### Debugging Tools

Add debugging capabilities:

```bash
# Debug image features
EXTRA_IMAGE_FEATURES += "debug-tweaks tools-debug"

# GDB and debugging tools
IMAGE_INSTALL:append = " gdb gdbserver strace ltrace"

# Kernel debugging
KERNEL_FEATURES:append = " features/debug/debug-kernel.scc"
```

## Conclusion

This tutorial provides a comprehensive guide to building and customizing a Yocto-based Linux system for the DE10-Standard board. The automated script handles most complexity, while the manual steps provide understanding of the process.

### Next Steps

1. **Explore FPGA integration** - Add FPGA-specific tools and drivers
2. **Customize for your application** - Add specific software packages
3. **Performance tuning** - Optimize for your use case
4. **Security hardening** - Remove debug features for production
5. **Update management** - Implement OTA update capabilities

### Resources

- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [DE10-Standard User Manual](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=&No=1081)
- [Intel SoC FPGA Documentation](https://www.intel.com/content/www/us/en/programmable/products/soc/cyclone-v.html)
- [Meta-Intel-FPGA Layer](https://github.com/altera-opensource/meta-intel-fpga-refdes)

### Support

For issues and questions:
- Check the troubleshooting section above
- Review Yocto Project mailing lists
- Consult Intel FPGA community forums
- Create issues in relevant GitHub repositories