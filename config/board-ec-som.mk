
UBOOT_CONFIG_TARGET = imx8m_lpddr4_som_defconfig
UBOOT_DTB = emcraft-imx8m-som.dtb

repo-branch@uboot = pureos-emcraft
repo-source@uboot = https://source.puri.sm/Librem5/uboot-imx.git

KERNEL_CONFIG_TARGET = librem5-evk
KERNEL_DTB = freescale/emcraft-imx8-som.dtb

repo-branch@linux = imx8-4.18-wip
repo-source@linux = https://source.puri.sm/Librem5/linux-emcraft.git

repo-branch@imx-mkimage = imx-mkimage-emcraft
repo-source@imx-mkimage = ../../.git
