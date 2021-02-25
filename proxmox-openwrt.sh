#!/bin/bash

function noterr() {
	$* 2>/dev/null
}

if [[ "$VMid" = "" ]]; then
	echo "Virtual Machine ID (\$VMid) has not been setup. Using default (100)"
	VMid=100
fi

if [[ $(noterr qm config $VMid) ]]; then
	echo "Error. VM $VMid Already exists. Aborting." >&2
	exit 1
fi

qm create $VMid
# cat /dev/null >/etc/pve/qemu-server/$VMid.conf
mkdir -p /var/lib/vz/images/$VMid
cd /var/lib/vz/images/$VMid

if [[ "$ImageFile" = "" ]]; then
	echo "Downloading release 19.01.7."
	echo "To override the image file, set the url in the Env var \$ImageFile."

	ImageFile="https://downloads.openwrt.org/releases/19.07.7/targets/x86/64/openwrt-19.07.7-x86-64-combined-ext4.img.gz"
fi

noterr curl -o openwrt-ext4.img.gz "$ImageFile"
gzip -d openwrt-ext4.img.gz

macaddr1="00:0E"$(for i in {1..4}; do echo -n ":"$(($RANDOM %10))$(($RANDOM %10)); done)
macaddr2="00:0E"$(for i in {1..4}; do echo -n ":"$(($RANDOM %10))$(($RANDOM %10)); done)
uuidtail="1e000"$(for i in {1..7}; do echo -n $(($RANDOM %10)); done)

tee /etc/pve/qemu-server/$VMid.conf << EOF >/dev/null
agent: 1,fstrim_cloned_disks=1
boot: order=scsi0
cores: 1
memory: 512
name: OpenWRT
net0: virtio=$macaddr1,bridge=vmbr0,firewall=1
net1: virtio=$macaddr2,bridge=vmbr0,firewall=1
numa: 0
onboot: 1
ostype: l26
protection: 1
scsi0: /var/lib/vz/images/$VMid/openwrt-ext4.img
scsihw: virtio-scsi-pci
smbios1: uuid=61646111-e41a-4c30-aa97-bbbedcbae31a
sockets: 1
startup: order=5,up=5,down=99
vga: qxl
vmgenid: 0c000000-2000-4000-a000-$uuidtail
EOF
