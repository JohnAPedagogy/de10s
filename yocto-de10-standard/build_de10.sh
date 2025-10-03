#!/bin/bash

# DE10-Standard Yocto Build Setup and Build Script
# This script automates the complete setup and build process for the DE10-Standard board

set -e  # Exit on any error

# Configuration
YOCTO_DIR="yocto-de10-standard"
BUILD_DIR="build"
MACHINE="cyclone5"
DISTRO="poky"
IMAGE_TARGET="core-image-minimal"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log "Checking build dependencies..."
    
    local missing_deps=()
    local required_packages=(
        "git" "build-essential" "python3" "python3-pip" "python3-venv"
        "gawk" "wget" "diffstat" "unzip" "texinfo" "gcc-multilib"
        "chrpath" "socat" "cpio" "xz-utils" "debianutils" "iputils-ping"
        "libegl1-mesa" "libsdl1.2-dev" "pylint3" "xterm" "file" "locales"
    )
    
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            missing_deps+=("$package")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing_deps[*]}. Please install them first."
    fi
    
    log "All dependencies satisfied"
}

# Setup workspace directory
setup_workspace() {
    log "Setting up workspace..."
    
    if [ ! -d "$YOCTO_DIR" ]; then
        mkdir -p "$YOCTO_DIR"
        cd "$YOCTO_DIR"
    else
        cd "$YOCTO_DIR"
        info "Using existing workspace: $(pwd)"
    fi
}

# Clone or update Yocto layers
setup_layers() {
    log "Setting up Yocto layers..."
    
    # Poky (main Yocto repository)
    if [ ! -d "poky" ]; then
        log "Cloning Poky repository..."
        git clone https://git.yoctoproject.org/poky.git
        cd poky
        git checkout scarthgap
        git reset --hard e3ce89324da1e33c17c9180ef846f41d92616254
        cd ..
    else
        log "Updating Poky..."
        cd poky
        git fetch origin
        git checkout scarthgap
        git reset --hard e3ce89324da1e33c17c9180ef846f41d92616254
        cd ..
    fi
    
    # Meta-OpenEmbedded
    if [ ! -d "meta-openembedded" ]; then
        log "Cloning Meta-OpenEmbedded repository..."
        git clone https://github.com/openembedded/meta-openembedded.git
        cd meta-openembedded
        git checkout scarthgap
        git reset --hard e621da947048842109db1b4fd3917a02e0501aa2
        cd ..
    else
        log "Updating Meta-OpenEmbedded..."
        cd meta-openembedded
        git fetch origin
        git checkout scarthgap
        git reset --hard e621da947048842109db1b4fd3917a02e0501aa2
        cd ..
    fi
    
    # Meta-Intel-FPGA-Refdes
    if [ ! -d "meta-intel-fpga-refdes" ]; then
        log "Cloning Meta-Intel-FPGA-Refdes repository..."
        git clone https://github.com/altera-opensource/meta-intel-fpga-refdes.git
        cd meta-intel-fpga-refdes
        git checkout scarthgap
        git reset --hard bffc5bc012f1653beb58878b54b44e74b0f27404
        cd ..
    else
        log "Updating Meta-Intel-FPGA-Refdes..."
        cd meta-intel-fpga-refdes
        git fetch origin
        git checkout scarthgap
        git reset --hard bffc5bc012f1653beb58878b54b44e74b0f27404
        cd ..
    fi
    
    # Meta-Intelfpga (robseb's enhanced layer)
    if [ ! -d "meta-intelfpga" ]; then
        log "Cloning Meta-Intelfpga repository..."
        git clone https://github.com/robseb/meta-intelfpga.git
        cd meta-intelfpga
        git checkout a71dba983ec5e1af96bc3556a959fb8d0fe1044e
        cd ..
    else
        log "Updating Meta-Intelfpga..."
        cd meta-intelfpga
        git fetch origin
        git checkout a71dba983ec5e1af96bc3556a959fb8d0fe1044e
        cd ..
    fi
}

# Apply local customizations to meta-intelfpga
apply_customizations() {
    log "Applying local customizations..."
    
    # Customize socfpga.inc for enhanced image formats
    local socfpga_inc="meta-intelfpga/conf/machine/include/socfpga.inc"
    if [ -f "$socfpga_inc" ]; then
        log "Customizing $socfpga_inc for enhanced image formats..."
        sed -i 's/IMAGE_FSTYPES ?= "tar.gz"/IMAGE_FSTYPES ?= "ext4 tar.gz wic wic.gz wic.bmap"/' "$socfpga_inc"
    fi
    
    # Add kernel development support comment to core-image-minimal.bbappend
    local bbappend="meta-intelfpga/recipes-core/images/core-image-minimal.bbappend"
    if [ -f "$bbappend" ] && ! grep -q "kernel-dev kernel-modules" "$bbappend"; then
        log "Adding kernel development support option to $bbappend..."
        echo "" >> "$bbappend"
        echo "# Add comprehensive kernel development support" >> "$bbappend"
        echo "# IMAGE_INSTALL:append = \" kernel-dev kernel-modules \"" >> "$bbappend"
    fi
}

# Create meta-de10-standard layer if it doesn't exist
create_de10_layer() {
    if [ ! -d "meta-de10-standard" ]; then
        log "Creating meta-de10-standard layer..."
        
        mkdir -p meta-de10-standard/conf
        mkdir -p meta-de10-standard/recipes-bsp/device-tree
        mkdir -p meta-de10-standard/recipes-example/example
        
        # Create layer.conf
        cat > meta-de10-standard/conf/layer.conf << 'EOF'
# We have a conf and classes directory, add to BBPATH
BBPATH .= ":${LAYERDIR}"

# We have recipes-* directories, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "meta-de10-standard"
BBFILE_PATTERN_meta-de10-standard = "^${LAYERDIR}/"
BBFILE_PRIORITY_meta-de10-standard = "6"

LAYERDEPENDS_meta-de10-standard = "core"
LAYERSERIES_COMPAT_meta-de10-standard = "scarthgap"
EOF

        # Create example recipe
        cat > meta-de10-standard/recipes-example/example/example_0.1.bb << 'EOF'
SUMMARY = "Example application for DE10-Standard"
DESCRIPTION = "Simple example application demonstrating DE10-Standard specific functionality"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = ""

do_install() {
    install -d ${D}${bindir}
    echo '#!/bin/bash' > ${D}${bindir}/de10-example
    echo 'echo "Hello from DE10-Standard!"' >> ${D}${bindir}/de10-example
    chmod +x ${D}${bindir}/de10-example
}
EOF

        # Create device tree recipe placeholder
        cat > meta-de10-standard/recipes-bsp/device-tree/device-tree-de10-standard_1.0.bb << 'EOF'
SUMMARY = "Device tree for DE10-Standard board"
DESCRIPTION = "Custom device tree configuration for DE10-Standard development board"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# This is a placeholder - actual device tree files would be added here
SRC_URI = ""

do_install() {
    # Device tree installation would be implemented here
    install -d ${D}${datadir}/device-tree
    # install -m 0644 ${WORKDIR}/de10-standard.dtb ${D}${datadir}/device-tree/
}
EOF
    fi
}

# Initialize build environment
init_build_env() {
    log "Initializing build environment..."
    
    # Source the Yocto environment
    source poky/oe-init-build-env "$BUILD_DIR"
    
    # We're now in the build directory
    log "Build environment initialized in $(pwd)"
}

# Configure build
configure_build() {
    log "Configuring build..."
    
    # Configure bblayers.conf
    cat > conf/bblayers.conf << EOF
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \\
  \${TOPDIR}/../poky/meta \\
  \${TOPDIR}/../poky/meta-poky \\
  \${TOPDIR}/../poky/meta-yocto-bsp \\
  \${TOPDIR}/../meta-openembedded/meta-oe \\
  \${TOPDIR}/../meta-openembedded/meta-python \\
  \${TOPDIR}/../meta-openembedded/meta-networking \\
  \${TOPDIR}/../meta-intelfpga \\
  \${TOPDIR}/../meta-de10-standard \\
  "
EOF

    # Configure local.conf with DE10-Standard specific settings
    cp conf/local.conf conf/local.conf.backup
    
    cat >> conf/local.conf << EOF

# DE10-Standard Configuration
MACHINE = "$MACHINE"
DISTRO = "$DISTRO"

# Enhanced image formats for DE10-Standard
IMAGE_FSTYPES += "wic wic.gz wic.bmap"

# Enable systemd and modern features
DISTRO_FEATURES:append = " systemd usrmerge"
VIRTUAL-RUNTIME_init_manager = "systemd"

# Parallel build optimization (adjust based on your system)
BB_NUMBER_THREADS ?= "\${@oe.utils.cpu_count()}"
PARALLEL_MAKE ?= "-j \${@oe.utils.cpu_count()}"

# Download and shared state directories (uncomment and customize if needed)
# DL_DIR ?= "\${TOPDIR}/../downloads"
# SSTATE_DIR ?= "\${TOPDIR}/../sstate-cache"

# Additional features for development
EXTRA_IMAGE_FEATURES ?= "debug-tweaks ssh-server-openssh package-management"

# License handling
LICENSE_FLAGS_ACCEPTED = "commercial"
EOF

    log "Build configuration completed"
}

# Perform the actual build
build_image() {
    log "Starting Yocto build for $IMAGE_TARGET..."
    log "This will take a significant amount of time (1-3 hours depending on your system)..."
    
    # Start the build
    time bitbake "$IMAGE_TARGET"
    
    if [ $? -eq 0 ]; then
        log "Build completed successfully!"
        log "Images are available in: tmp/deploy/images/$MACHINE/"
        
        # List the generated images
        info "Generated image files:"
        ls -lh tmp/deploy/images/$MACHINE/*.wic* tmp/deploy/images/$MACHINE/*.ext4 2>/dev/null || true
    else
        error "Build failed! Check the output above for errors."
    fi
}

# Main execution
main() {
    log "Starting DE10-Standard Yocto Build Setup"
    
    # Parse command line arguments
    CLEAN_BUILD=false
    SKIP_BUILD=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --setup-only)
                SKIP_BUILD=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --clean      Remove existing build directory and start fresh"
                echo "  --setup-only Setup layers and configuration but don't build"
                echo "  --help       Show this help message"
                exit 0
                ;;
            *)
                warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Check system dependencies
    check_dependencies
    
    # Setup workspace
    setup_workspace
    
    # Clean build if requested
    if [ "$CLEAN_BUILD" = true ] && [ -d "$BUILD_DIR" ]; then
        warning "Removing existing build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    # Setup all layers
    setup_layers
    
    # Apply local customizations
    apply_customizations
    
    # Create local layer
    create_de10_layer
    
    # Initialize build environment
    init_build_env
    
    # Configure build
    configure_build
    
    # Build unless skip requested
    if [ "$SKIP_BUILD" = false ]; then
        build_image
        
        log "Build process completed!"
        log "To flash the image to an SD card, use:"
        info "sudo dd if=tmp/deploy/images/$MACHINE/$IMAGE_TARGET-$MACHINE.wic of=/dev/sdX bs=1M status=progress"
        info "Or use bmaptool for faster flashing:"
        info "sudo bmaptool copy tmp/deploy/images/$MACHINE/$IMAGE_TARGET-$MACHINE.wic.gz /dev/sdX"
    else
        log "Setup completed! To build manually, run:"
        info "cd $YOCTO_DIR"
        info "source poky/oe-init-build-env $BUILD_DIR"
        info "bitbake $IMAGE_TARGET"
    fi
}

# Run main function
main "$@"