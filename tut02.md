# tut02: Build a Yocto Image for the Terasic DE10-Standard (Cyclone V SoC)

This tutorial adapts the structure of nano_steps.md and uses the Bitlog reference as background context, but switches the build system to Yocto/OpenEmbedded and targets the DE10-Standard board.

## Links
- Yocto Project Quick Build: https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html
- Poky (Yocto reference distro): https://git.yoctoproject.org/poky/
- meta-openembedded layer: https://github.com/openembedded/meta-openembedded
- meta-intel-fpga-refdes layer: https://github.com/altera-opensource/meta-intel-fpga-refdes
- bmaptool: https://github.com/intel/bmaptool
- Bitlog reference (background): https://bitlog.it/20170820_building_embedded_linux_for_the_terasic_de10-nano.html
- [cyclone5 layer for DE 10](https://layers.openembedded.org/layerindex/branch/master/layer/meta-intelfpga/)

## Project Overview

Goal: Build an embedded Linux image for the Terasic DE10-Standard development board (Cyclone V SoC) using Yocto/OpenEmbedded. The DE10-Standard combines a dual-core ARM Cortex-A9 (HPS) with FPGA fabric.

## Architecture

Typical Yocto-based embedded Linux workflow:
- Define target MACHINE and layers (poky + meta-openembedded + meta-intel-fpga-refdes)
- Configure U-Boot and Linux kernel for SoCFPGA
- Configure root filesystem via Yocto recipes and images
- Build with bitbake and produce deployable SD card image
- Boot on hardware and iterate (package selection, kernel config, device tree)

## Build Process

Note: Yocto is best supported on a recent Linux host (Ubuntu 22.04+). On macOS, use a Docker container or a Linux VM.

### Step 0: Preparation
- Linux host prerequisites (Ubuntu/Debian example):
  - sudo apt-get update
  - sudo apt-get install gawk wget git diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping bmap-tools
- macOS option (Docker):
  - Install Docker Desktop
  - Use a Yocto-capable container (example):
    - docker run --rm -it -v $PWD:/work -w /work ubuntu:22.04 bash
    - Inside container: apt-get update && apt-get install -y gawk wget git diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils iputils-ping bmap-tools locales && locale-gen en_US.UTF-8

### Step 1: Get Yocto sources and layers
- Install Python 3.11 and pipenv if they don't exist:
  - sudo apt install python3.11 pipenv
- Choose a stable Yocto release (Scarthgap LTS is widely used). In a working directory, run:
  - mkdir yocto-de10-standard && cd yocto-de10-standard
  - pipenv install --python=3.11
  - git clone -b scarthgap https://git.yoctoproject.org/poky
  - git clone -b scarthgap https://github.com/openembedded/meta-openembedded
  - git clone -b scarthgap https://github.com/altera-opensource/meta-intel-fpga-refdes

### Step 2: Initialize the build environment
- Activate the pipenv environment:
  - pipenv shell
- Source the environment and create a build directory:
  - source poky/oe-init-build-env build
- Add required layers:
  - bitbake-layers add-layer ../meta-openembedded/meta-oe
  - bitbake-layers add-layer ../meta-openembedded/meta-networking
  - bitbake-layers add-layer ../meta-openembedded/meta-python
  - bitbake-layers add-layer ../meta-intel-fpga-refdes

### Step 3: Configure MACHINE and image settings
- Edit conf/local.conf (created by oe-init-build-env). Key settings:
  - MACHINE ?= "cyclone5"
    - Note: This is the generic SoCFPGA Cyclone V machine in meta-intel-fpga-refdes. If a board-specific machine for DE10-Standard is available in your chosen layer set, you may use it instead. Otherwise, use cyclone5 and set the device tree accordingly.
  - IMAGE_FSTYPES += "wic.gz"
  - EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
  - DISTRO_FEATURES:append = " systemd"
  - VIRTUAL-RUNTIME_init_manager = "systemd"
  - PACKAGE_CLASSES ?= "package_ipk"
- Device Tree selection (adjust as appropriate):
  - If you have (or create) a DE10-Standard device tree in the kernel, set:
    - KERNEL_DEVICETREE = "socfpga_cyclone5_de10_standard.dtb"
  - Otherwise, start with a generic Cyclone V HPS DTB and plan to customize later:
    - KERNEL_DEVICETREE = "socfpga_cyclone5.dtb"

### Step 4: Optional custom layer for board specifics
- If you need to add a custom DTS or board-specific settings, create your own layer and bbappends:
  - bitbake-layers create-layer ../meta-de10standard
  - bitbake-layers add-layer ../meta-de10standard
- Add a linux-socfpga bbappend to set KERNEL_DEVICETREE and/or add your DTS file. Place DTS at: meta-de10standard/recipes-kernel/linux/linux-socfpga/`<files>`

### Step 4a: DE10-Standard GSRD Device Tree Layer (Recommended)
**For proper DE10-Standard FPGA hardware support:**

The DE10-Standard requires a specific device tree that includes FPGA components (LEDs, buttons, DIP switches, JTAG UART) and proper hardware configuration. This section creates a custom layer with the DE10-Standard GSRD device tree.

#### Files Created:
1. **Custom Layer Configuration**:
   ```
   /meta-de10-standard/conf/layer.conf
   ```

2. **Device Tree Recipe**:
   ```
   /meta-de10-standard/recipes-bsp/device-tree/device-tree-de10-standard_1.0.bb
   ```

3. **DE10-Standard Device Tree Source**:
   ```
   /meta-de10-standard/recipes-bsp/device-tree/files/socfpga_cyclone5_de10_standard.dts
   ```

#### Configuration Changes Required:

1. **Add layer to build** (`conf/bblayers.conf`):
   ```
   BBLAYERS ?= " \
     .../meta-de10-standard \
     "
   ```

2. **Update device tree selection** (`conf/local.conf`):
   ```bash
   # Change from generic SoCDK device tree:
   # KERNEL_DEVICETREE = "socfpga_cyclone5_socdk.dtb"
   # To DE10-Standard specific device tree:
   KERNEL_DEVICETREE = "socfpga_cyclone5_de10_standard.dtb"

   # Include device tree package in image:
   IMAGE_INSTALL:append = " device-tree-de10-standard"
   ```

#### DE10-Standard Device Tree Features:
- **Model**: "Terasic DE10 Standard"
- **FPGA Components**:
  - LED GPIO (10 LEDs) - `/dev/led_pio`
  - Button GPIO (4 buttons) - `/dev/button_pio`
  - DIP Switch GPIO (10 switches) - `/dev/dipsw_pio`
  - JTAG UART - `/dev/jtag_uart`
- **Hardware Interfaces**: Ethernet (GMAC1), I2C, SPI, QSPI Flash, SD/MMC, USB
- **FPGA Bridges**: HPS-to-FPGA, FPGA-to-HPS, FPGA-to-SDRAM communication bridges
- **Memory**: 2GB DDR3 SDRAM configuration
- **Clocking**: 25MHz oscillators, PLL configurations for SoC and FPGA

#### Layer Structure:
```
meta-de10-standard/
├── conf/
│   └── layer.conf                    # Layer configuration
└── recipes-bsp/
    └── device-tree/
        ├── device-tree-de10-standard_1.0.bb      # Recipe
        └── files/
            └── socfpga_cyclone5_de10_standard.dts # Device tree source
```

This layer ensures the build system uses the proper DE10-Standard device tree instead of the generic SoCDK device tree, enabling full hardware support for FPGA-specific components.

### Step 5: Build the image
- From the build directory:
  - bitbake core-image-minimal
- This will build U-Boot, the kernel, and a minimal root filesystem.

### Step 5a: Automated Build Monitor Script (Recommended)
**For reliable, hands-off building with automatic failure recovery:**

The build monitor script automatically handles package build failures and continues until completion.

#### Prerequisites (Already Done if Following Steps 1-4):
- Yocto environment initialized
- Machine configured as `cyclone5` in `conf/local.conf`
- All layers properly added

#### Using the Build Monitor Script:

1. **Create and make executable** (one-time setup):
   ```bash
   # From your yocto-de10-standard directory
   chmod +x build_monitor.sh
   ```

2. **Run the automated build**:
   ```bash
   # Run in foreground (shows output)
   ./build_monitor.sh

   # OR run in background (recommended for long builds)
   ./build_monitor.sh &
   ```

3. **Monitor progress**:
   ```bash
   # View live log output
   tail -f build/build_monitor.log

   # Check if script is still running
   ps aux | grep build_monitor

   # Check for completed image
   ls -la build/tmp/deploy/images/cyclone5/
   ```

#### Script Features:
- **Automatic Failure Recovery**: Detects failed packages and cleans them individually
- **Intelligent Retry Logic**: Continues building after resolving failures
- **Progress Tracking**: Colored output shows build status (Green=Success, Red=Error, Yellow=Warning)
- **Complete Logging**: All build activity saved to `build/build_monitor.log`
- **Success Detection**: Automatically stops when cyclone5 image is ready

#### Script Behavior:
1. Runs `bitbake core-image-minimal` targeting cyclone5
2. If build fails, parses logs to identify failed packages
3. Cleans failed packages with `bitbake -c clean <package>`
4. Retries build automatically
5. Continues until `*.wic` files appear in `/tmp/deploy/images/cyclone5/`
6. Reports final success with image locations

#### Manual Control Commands:
```bash
# Stop the script (if needed)
pkill -f build_monitor.sh

# Kill all bitbake processes (emergency stop)
pkill -f bitbake

# View recent build progress
tail -50 build/build_monitor.log
```

#### Success Criteria:
The script completes when these files exist:
- **Directory**: `build/tmp/deploy/images/cyclone5/`
- **Image File**: `core-image-minimal-cyclone5.wic` (SD card image)
- **Additional**: Kernel, device tree, and bootloader components

**Typical Build Time**: 2-4 hours on modern hardware for first build

#### Troubleshooting the Script:
- **Script exits early**: Check `build/build_monitor.log` for specific errors
- **Repeated failures**: Review failed package logs in `build/tmp/work/`
- **No progress**: Verify bitbake environment is properly initialized
- **Manual intervention needed**: Use `bitbake -c clean <package>` then restart script

### Step 6: Locate build artifacts
- Outputs are in: build/tmp/deploy/images/${MACHINE}/
- Typical files:
  - core-image-minimal-${MACHINE}.wic.gz (bootable SD card image)
  - zImage or Image (kernel)
  - *.dtb (device tree blob)
  - u-boot-spl and u-boot.img (bootloader components)

### Step 7: Flash the SD card image
- On Linux/macOS (with appropriate device node):
  - gunzip -c core-image-minimal-${MACHINE}.wic.gz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
  - Or use bmaptool for faster flashing:
    - sudo bmaptool copy core-image-minimal-${MACHINE}.wic.gz /dev/sdX
- Replace /dev/sdX with your SD card device. Be careful to choose the correct device.

### Step 8: Configure the board and boot
- Set the DE10-Standard MSEL pins for SD boot (refer to the board manual).
- Insert the SD card.
- Connect a USB-UART cable and open a serial console (115200 8N1):
  - Linux example: screen /dev/ttyUSB0 115200
  - macOS example: screen /dev/tty.usbserial-XXXX 115200
- Power on the board. U-Boot should load the kernel and DTB from the SD image.

### Step 9: Verify and iterate
- After boot, log in (core-image-minimal usually has root with no password).
- Verify basic peripherals (Ethernet link, storage, LEDs if exposed via sysfs).
- Iterate as needed:
  - Add packages to IMAGE_INSTALL in local.conf or via a custom image recipe
  - Customize kernel config via menuconfig fragment or bbappend
  - Provide a board-accurate device tree for DE10-Standard

### Step 10: Troubleshooting

#### Build-Related Issues:
- **Use the Build Monitor Script**: For most build failures, the automated script (Step 5a) handles package failures automatically
- **Manual build failures**: Ensure your host meets Yocto requirements and you are using consistent branches (scarthgap in this example) for all layers
- **Persistent package failures**: Check logs in `build/tmp/work/<package>/` and use `bitbake -c clean <package>` before retrying
- **Common scarthgap issues**: Some packages (like shared-mime-info-native) may have pkgconfig dependency issues - these are automatically resolved by the build monitor script

#### Hardware/Boot Issues:
- **Device tree issues**: if peripherals don't enumerate, verify the correct DTB is used. Start from a known-good SoCFPGA DT (socfpga_cyclone5*.dts) and adapt for DE10-Standard.
- **U-Boot environment**: if boot fails, use the serial console to inspect U-Boot output and environment. Ensure the boot targets and partition labels match the WIC image.

## Key Components
- U-Boot: Bootloader for SoCFPGA (u-boot-socfpga)
- Linux kernel: SoCFPGA kernel (linux-socfpga) with appropriate DTB
- Root filesystem: Generated by Yocto (core-image-minimal or a custom image)
- SD card image: WIC image generated by bitbake
- Layers: poky, meta-openembedded (meta-oe, meta-networking, meta-python), meta-socfpga, plus optional custom layer

## Development Tools Required
- Host build tools (see Step 0)
- Serial console (screen, minicom, or picocom)
- SD card writer (dd or bmaptool)
- **Automated Build Monitor Script**: `build_monitor.sh` for reliable, hands-off building with failure recovery

## Reference
- Background guide used for context: https://bitlog.it/20170820_building_embedded_linux_for_the_terasic_de10-nano.html
- Yocto documentation: https://docs.yoctoproject.org/
- meta-intel-fpga-refdes: https://github.com/altera-opensource/meta-intel-fpga-refdes
- Cyclone 5 preferred: https://layers.openembedded.org/layerindex/branch/master/layer/meta-intelfpga/

## Repository Update Notes
- **Previous repository:** `https://github.com/kraj/meta-socfpga` (deprecated)
- **Current repository:** `https://github.com/altera-opensource/meta-intel-fpga-refdes` (official Intel/Altera)
- **Cyclone 5 preferred repository**: `https://layers.openembedded.org/layerindex/branch/master/layer/meta-intelfpga/`

## Summary
1. Project Structure Created:
    - Working directory: /home/its/tools/yocto/de10/yocto-de10-standard
    - Git repository initialized with remote reference
    - Comprehensive progress.md checklist created
  2. Yocto Environment Configured:
    - Python 3.11 pipenv virtual environment
    - Yocto scarthgap branch (LTS) sources cloned
    - Required layers added: meta-oe, meta-python, meta-networking, meta-intelfpga
  3. DE10-Standard Specific Configuration:
    - MACHINE: cyclone5
    - Custom Device Tree: socfpga_cyclone5_de10_standard.dtb
    - FPGA Components Supported: LEDs, buttons, DIP switches, JTAG UART
    - Image Format: WIC image for SD card deployment
    - Init System: systemd
    - Debug Features: Enabled for development
  4. DE10-Standard Custom Layer (meta-de10-standard):
    - Device tree source: socfpga_cyclone5_de10_standard.dts
    - Recipe: device-tree-de10-standard_1.0.bb
    - Hardware Support Includes:
      - 10 LEDs (LED0-LED9) accessible via /dev/led_pio
      - 4 Buttons (KEY0-KEY3) accessible via /dev/button_pio
      - 10 DIP Switches (SW0-SW9) accessible via /dev/dipsw_pio
      - JTAG UART accessible via /dev/jtag_uart
      - Ethernet (GMAC1), I2C, SPI, QSPI Flash, SD/MMC, USB
      - FPGA bridges for HPS-FPGA communication
  5. Build Configuration:
    - Fixed parsing errors by removing problematic layers
    - Build monitoring script created for automatic failure recovery
    - .gitignore configured to exclude build artifacts