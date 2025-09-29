# DE10-Standard Yocto Build Progress

This checklist tracks the progress of building a Yocto image for the Terasic DE10-Standard (Cyclone V SoC) board using the meta-intelfpga layer.

## Project Setup
- [ ] **Repository Initialization**
  - [ ] Initialize git repository
  - [ ] Add remote reference to https://github.com/JohnAPedagogy/de10s.git
  - [ ] Create initial commit with tutorial files
  - [ ] Configure .gitignore for build artifacts (tmp/, sstate-cache/, cache/)

## Prerequisites (Step 0)
- [ ] **Host System Preparation**
  - [ ] Verify Linux host (Ubuntu 22.04+ preferred)
  - [ ] Install build dependencies:
    ```bash
    sudo apt-get update
    sudo apt-get install gawk wget git diffstat unzip texinfo gcc-multilib \
                         build-essential chrpath socat cpio python3 python3-pip \
                         python3-pexpect xz-utils debianutils iputils-ping bmap-tools
    ```
  - [ ] Install Python 3.11 and pipenv: `sudo apt install python3.11 pipenv`

## Yocto Environment Setup (Steps 1-2)
- [ ] **Source Code Acquisition**
  - [ ] Create project directory: `mkdir yocto-de10-standard && cd yocto-de10-standard`
  - [ ] Setup pipenv: `pipenv install --python=3.11`
  - [ ] Clone Yocto sources (scarthgap branch):
    - [ ] `git clone -b scarthgap https://git.yoctoproject.org/poky`
    - [ ] `git clone -b scarthgap https://github.com/openembedded/meta-openembedded`
    - [ ] `git clone -b scarthgap https://github.com/altera-opensource/meta-intel-fpga-refdes`
    - [ ] Clone meta-intelfpga for Cyclone 5 support

- [ ] **Build Environment Initialization**
  - [ ] Activate pipenv: `pipenv shell`
  - [ ] Source environment: `source poky/oe-init-build-env build`
  - [ ] Add required layers:
    - [ ] `bitbake-layers add-layer ../meta-openembedded/meta-oe`
    - [ ] `bitbake-layers add-layer ../meta-openembedded/meta-networking`
    - [ ] `bitbake-layers add-layer ../meta-openembedded/meta-python`
    - [ ] `bitbake-layers add-layer ../meta-intel-fpga-refdes`
    - [ ] Add meta-intelfpga layer for Cyclone 5

## Build Configuration (Step 3)
- [ ] **Configure conf/local.conf**
  - [ ] Set MACHINE: `MACHINE ?= "cyclone5"`
  - [ ] Add image format: `IMAGE_FSTYPES += "wic.gz"`
  - [ ] Enable debug features: `EXTRA_IMAGE_FEATURES ?= "debug-tweaks"`
  - [ ] Configure systemd:
    - [ ] `DISTRO_FEATURES:append = " systemd"`
    - [ ] `VIRTUAL-RUNTIME_init_manager = "systemd"`
  - [ ] Set package format: `PACKAGE_CLASSES ?= "package_ipk"`
  - [ ] Configure device tree: `KERNEL_DEVICETREE = "socfpga_cyclone5.dtb"`

## DE10-Standard Custom Layer (Step 4a - Recommended)
- [ ] **Create Custom Layer for DE10-Standard**
  - [ ] Create layer: `bitbake-layers create-layer ../meta-de10-standard`
  - [ ] Add layer: `bitbake-layers add-layer ../meta-de10-standard`
  - [ ] Create layer structure:
    ```
    meta-de10-standard/
    ├── conf/layer.conf
    └── recipes-bsp/device-tree/
        ├── device-tree-de10-standard_1.0.bb
        └── files/socfpga_cyclone5_de10_standard.dts
    ```
  - [ ] Update conf/local.conf for DE10-Standard device tree:
    - [ ] `KERNEL_DEVICETREE = "socfpga_cyclone5_de10_standard.dtb"`
    - [ ] `IMAGE_INSTALL:append = " device-tree-de10-standard"`

## Build Process (Steps 5-5a)
- [ ] **Initial Build Attempt**
  - [ ] Manual build: `bitbake core-image-minimal`
  - [ ] Monitor for errors and failures

- [ ] **Automated Build Monitor (Recommended)**
  - [ ] Create build monitor script: `build_monitor.sh`
  - [ ] Make executable: `chmod +x build_monitor.sh`
  - [ ] Run automated build: `./build_monitor.sh`
  - [ ] Monitor progress: `tail -f build/build_monitor.log`
  - [ ] Verify completion when *.wic files appear in `build/tmp/deploy/images/cyclone5/`

## Build Artifacts Verification (Step 6)
- [ ] **Locate and Verify Build Outputs**
  - [ ] Navigate to: `build/tmp/deploy/images/cyclone5/`
  - [ ] Verify presence of:
    - [ ] `core-image-minimal-cyclone5.wic.gz` (bootable SD card image)
    - [ ] `zImage` or `Image` (kernel)
    - [ ] `*.dtb` (device tree blob)
    - [ ] `u-boot-spl` and `u-boot.img` (bootloader components)

## SD Card Preparation (Step 7)
- [ ] **Flash SD Card Image**
  - [ ] Identify SD card device: `lsblk`
  - [ ] Flash using dd: `gunzip -c core-image-minimal-cyclone5.wic.gz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync`
  - [ ] OR use bmaptool: `sudo bmaptool copy core-image-minimal-cyclone5.wic.gz /dev/sdX`
  - [ ] Verify flash completed successfully

## Hardware Setup and Boot (Step 8)
- [ ] **Board Configuration**
  - [ ] Set DE10-Standard MSEL pins for SD boot
  - [ ] Insert flashed SD card
  - [ ] Connect USB-UART cable
  - [ ] Open serial console (115200 8N1): `screen /dev/ttyUSB0 115200`
  - [ ] Power on board
  - [ ] Verify U-Boot loads and kernel boots

## System Verification (Step 9)
- [ ] **Boot Verification**
  - [ ] Log in (typically root with no password)
  - [ ] Verify basic peripherals:
    - [ ] Ethernet link
    - [ ] Storage access
    - [ ] LEDs (if exposed via sysfs)
    - [ ] FPGA components (buttons, switches, JTAG UART)

## Repository Management
- [ ] **Final Repository Setup**
  - [ ] Configure .gitignore to exclude:
    - [ ] `build/tmp/`
    - [ ] `build/sstate-cache/`
    - [ ] `build/cache/`
    - [ ] `build/downloads/`
  - [ ] Add build configuration files
  - [ ] Add custom layers and scripts
  - [ ] Commit final build environment
  - [ ] Push to remote repository

## Troubleshooting Reference (Step 10)
- [ ] **Build Issues**
  - [ ] Use build monitor script for automatic failure recovery
  - [ ] For manual failures: check logs in `build/tmp/work/<package>/`
  - [ ] Clean failed packages: `bitbake -c clean <package>`
  - [ ] Verify consistent branch usage across all layers

- [ ] **Hardware/Boot Issues**
  - [ ] Verify correct DTB usage
  - [ ] Check U-Boot environment via serial console
  - [ ] Ensure boot targets match WIC image

## Key Resources
- Yocto Project Quick Build: https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html
- meta-intelfpga (Cyclone 5): https://layers.openembedded.org/layerindex/branch/master/layer/meta-intelfpga/
- meta-intel-fpga-refdes: https://github.com/altera-opensource/meta-intel-fpga-refdes
- Bitlog reference: https://bitlog.it/20170820_building_embedded_linux_for_the_terasic_de10-nano.html

## Build Status
- **Target**: core-image-minimal for cyclone5 machine
- **Expected Output**: bootable WIC image for DE10-Standard board
- **Estimated Build Time**: 2-4 hours (first build)
- **Success Criteria**: Bootable Linux system with FPGA hardware support