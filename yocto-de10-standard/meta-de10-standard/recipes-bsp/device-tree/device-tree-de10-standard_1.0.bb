SUMMARY = "Device tree for Terasic DE10-Standard board"
DESCRIPTION = "Device tree source and compiled blob for DE10-Standard (Cyclone V SoC)"
SECTION = "bsp"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit devicetree

PROVIDES = "virtual/dtb"

SRC_URI = "file://socfpga_cyclone5_de10_standard.dts"

S = "${WORKDIR}"

COMPATIBLE_MACHINE = "cyclone5"

# Install the device tree blob
do_install() {
    install -d ${D}/boot
    install -m 0644 ${B}/socfpga_cyclone5_de10_standard.dtb ${D}/boot/
}

FILES:${PN} = "/boot/socfpga_cyclone5_de10_standard.dtb"

# Create a package for the device tree
PACKAGES = "${PN}"