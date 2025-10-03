# DE10-Standard Yocto Build - Layer Information

## Build Configuration Summary
- **Machine**: cyclone5 (DE10-Standard board with Cyclone V SoC)
- **Distribution**: poky (standard Yocto distribution)
- **Yocto Release**: Scarthgap
- **Architecture**: ARM Cortex-A9 dual-core
- **Image Types**: ext4, tar.gz, wic, wic.gz, wic.bmap
- **Features**: systemd, usrmerge

## Layer Dependencies and Versions

### 1. Poky (Core Yocto Layer)
- **Path**: `poky/meta`, `poky/meta-poky`, `poky/meta-yocto-bsp`
- **Repository**: https://git.yoctoproject.org/poky
- **Branch**: scarthgap
- **Commit**: e3ce89324da1e33c17c9180ef846f41d92616254
- **Status**: Clean (no local modifications)
- **Purpose**: Core Yocto build system, base recipes, and BSP support

### 2. Meta-OpenEmbedded
- **Path**: `meta-openembedded/meta-oe`, `meta-openembedded/meta-python`, `meta-openembedded/meta-networking`
- **Repository**: https://github.com/openembedded/meta-openembedded
- **Branch**: scarthgap  
- **Commit**: e621da947048842109db1b4fd3917a02e0501aa2
- **Status**: Clean (no local modifications)
- **Purpose**: Extended recipes for additional software packages, Python support, networking tools

### 3. Meta-Intel-FPGA-Refdes (Intel FPGA Reference Design)
- **Path**: `meta-intel-fpga-refdes`
- **Repository**: https://github.com/altera-opensource/meta-intel-fpga-refdes
- **Branch**: scarthgap
- **Commit**: bffc5bc012f1653beb58878b54b44e74b0f27404
- **Status**: Clean (no local modifications)
- **Purpose**: Intel/Altera FPGA reference design recipes and configurations

### 4. Meta-Intelfpga (Custom FPGA Layer)
- **Path**: `meta-intelfpga`
- **Repository**: https://github.com/robseb/meta-intelfpga.git
- **Branch**: Detached HEAD
- **Commit**: a71dba983ec5e1af96bc3556a959fb8d0fe1044e
- **Status**: Modified (local customizations applied)
- **Purpose**: Enhanced Intel SoC FPGA support with additional tools and configurations

**Local Modifications in meta-intelfpga:**
1. **conf/machine/include/socfpga.inc**:
   - `IMAGE_FSTYPES ?= "ext4 tar.gz wic wic.gz wic.bmap"` (enhanced image formats)

2. **recipes-core/images/core-image-minimal.bbappend**:
   - Added comprehensive systemd and SSH support
   - Enhanced boot file configuration for WIC images
   - Added kernel development support (commented for future use)

### 5. Meta-DE10-Standard (Local Custom Layer)
- **Path**: `meta-de10-standard`
- **Repository**: Local layer (part of main repository)
- **Purpose**: DE10-Standard board specific configurations and device tree

**Key Components:**
- Device tree recipe: `recipes-bsp/device-tree/device-tree-de10-standard_1.0.bb`
- Example recipe: `recipes-example/example/example_0.1.bb`
- Layer configuration: `conf/layer.conf`

## Build Environment
- **Downloads Directory**: Default (build/downloads)
- **Shared State Cache**: Default (build/sstate-cache)
- **Build Output**: build/tmp/deploy/images/cyclone5/

## Image Outputs
- **WIC Image**: Bootable SD card image with proper partitioning
- **Root Filesystem**: ext4 format for main system
- **Compressed Archives**: tar.gz for backup/deployment
- **Block Map**: wic.bmap for efficient flashing

## Dependencies
- All layers are compatible with Yocto Scarthgap release
- No conflicts between layer versions
- Proper BBFILE_PRIORITY configurations maintained