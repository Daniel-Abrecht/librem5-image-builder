BOARD = devkit
IMGSIZE = 4GiB # Note: 1GB = 1000MB, 1GiB=1024MiB 
DISTRO = devuan
RELEASE = $(DEFAULT_RELEASE-$(DISTRO))
REPO = http://pkgmaster.devuan.org/merged/
CHROOT_REPO = $(REPO)

REPO-devuan = http://pkgmaster.devuan.org/merged/
REPO-debian = http://deb.debian.org/debian/
REPO-ubuntu = http://ports.ubuntu.com/ubuntu-ports/

DEFAULT_RELEASE-devuan = beowulf
DEFAULT_RELEASE-debian = buster
DEFAULT_RELEASE-ubuntu = disco

IMAGE_NAME = $(DISTRO)-$(RELEASE)-librem5-$(BOARD)-base.img

CROSS_COMPILER = aarch64-linux-gnu-

repo-branch@fuseloop = master
repo-source@fuseloop = https://github.com/jmattsson/fuseloop.git

repo-branch@usernsexec = master
repo-source@usernsexec = https://github.com/Daniel-Abrecht/usernsexec.git

repo-branch@tar2ext = master
repo-source@tar2ext = https://github.com/Daniel-Abrecht/tar2ext.git

repo-branch@Cortex_M4 = master
repo-source@Cortex_M4 = https://source.puri.sm/Librem5/Cortex_M4.git

repo-branch@arm-trusted-firmware = imx_4.9.51_imx8m_beta
repo-source@arm-trusted-firmware = https://source.codeaurora.org/external/imx/imx-atf
