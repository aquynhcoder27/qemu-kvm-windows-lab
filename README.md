# lab-kvm

Reusable QEMU/KVM lab for learning Windows system administration and networking.
The lab has one Windows Server 2022 VM and two Windows 7 VMs. VM images and ISOs
live on a removable USB SSD. The Linux host remains usable when the SSD is absent.

## Host requirements

- Linux host with KVM/VT-x or AMD-V, libvirt and a USB SSD.
- Enough RAM for the host and the VMs you run together. The example sizes use
  2.5 GiB for the server and 1.5 GiB for each Windows 7 client.
- A NAT libvirt network for guest-to-guest, guest-to-host and Internet access.
  New labs use the project-owned **lab-kvm-nat** network. An existing lab may
  choose **default** in its local configuration.

The new network uses 192.168.233.0/24. If this overlaps a LAN or VPN route,
edit **networks/lab-nat.xml** before defining the network.

On Ubuntu:

~~~bash
sudo apt install qemu-system-x86 qemu-utils libvirt-daemon-system \
  libvirt-clients virtinst virt-manager cpu-checker ovmf parted
sudo usermod -aG kvm,libvirt "$USER"
~~~

Log out and back in after changing groups. Check KVM with **kvm-ok**.

## Configure this host

~~~bash
cp config.local.example.sh config.local.sh
lsblk -o NAME,SIZE,TRAN,MODEL,SERIAL,FSTYPE,UUID,MOUNTPOINTS
ls -l /dev/disk/by-id/
~~~

Edit **config.local.sh**:

- **LAB_FS_UUID**: UUID of the ext4 filesystem on the lab SSD. This is required
  before mounting, creating images or starting a VM.
- **LAB_DISK**: whole-disk /dev/disk/by-id/... path. It is used only for
  **setup-disk.sh --format**; leave it unset if the SSD is already formatted.
- **LAB_NET**: leave the default **lab-kvm-nat** for a new lab. Set **default**
  only if your existing VMs already use that NAT network.

**config.local.sh** is ignored by Git. VM names and sizes have portable defaults
in **config.sh**. If you change a VM name after defining it, update the libvirt
definition separately.

## Prepare an existing ext4 SSD

After setting **LAB_FS_UUID**:

~~~bash
sudo scripts/setup-disk.sh
scripts/setup-libvirt.sh
~~~

The mount script accepts only the configured filesystem UUID. It creates an
optional **fstab** entry with a five-second device timeout if no entry exists.
It refuses an existing entry that points to a different disk or waits at boot.
The storage pool is not set to autostart, because the SSD is removable. If an
existing **ISOs** pool points inside this SSD, the script also disables its
autostart and activates it when the SSD is connected.

## Initialize a new blank USB SSD

**This erases the selected disk.** Set **LAB_DISK** to its whole-disk by-id path,
verify its model and serial, then run:

~~~bash
sudo scripts/setup-disk.sh --format
~~~

The script accepts only a blank USB disk with no partitions or filesystem and
requires you to type the complete by-id name. It will not reformat an existing
disk. Copy the UUID it prints into **LAB_FS_UUID** in **config.local.sh**, then
run the two commands in the previous section.

## Create VMs

Put the ISO files under **/mnt/lab-vms/ISOs/**. Required: **win-server-2022.iso**
and **virtio-win.iso**. Optional: **win7.iso**. See
[ISO-DOWNLOAD-GUIDE.md](ISO-DOWNLOAD-GUIDE.md).

~~~bash
scripts/create-vms.sh
virt-manager
~~~

Creation stops if the configured SSD is not mounted. Existing qcow2 images and
libvirt VM definitions are reused, so the installed VMs are retained. The
Windows 7 definitions are skipped if **win7.iso** is absent. New Windows 7
definitions use an emulated **e1000** network adapter so networking works
without a VirtIO network driver during setup.

| VM | Role | vCPU | RAM | Virtual disk |
| --- | --- | ---: | ---: | ---: |
| win-srv-01 | Windows Server 2022 | 2 | 2.5 GiB | 35 GiB |
| win-w7-01 | Windows 7 client | 1 | 1.5 GiB | 20 GiB |
| win-w7-02 | Windows 7 client | 1 | 1.5 GiB | 20 GiB |

The helper limits starts to two lab VMs at a time. Shut down Windows inside
each VM before unplugging the SSD.

During Windows 7 setup, if no disk appears, choose **Load Driver** and browse
the attached **virtio-win.iso** to **viostor/w7/amd64** (or **x86** for 32-bit
Windows). This is the driver for the VirtIO system disk.

After installing a Windows 7 guest, shut it down and run `virsh edit <vm-name>`.
In the `<os>` section, put `<boot dev='hd'/>` before `<boot dev='cdrom'/>`.
Otherwise, an attached installer ISO can bring the VM back to the Windows
installer on the next start. Keep the CD-ROM first until installation is
finished; `win-w7-02` is an uninstalled example. Do not reinstall Windows or
replace the qcow2 image when this happens.

## Daily use and Internet check

Connect the SSD, then:

~~~bash
sudo scripts/setup-disk.sh
scripts/lab-vm.sh list
scripts/lab-vm.sh start win-srv-01
scripts/lab-vm.sh console win-srv-01
scripts/lab-vm.sh ip
scripts/lab-vm.sh stop win-srv-01
~~~

The start command verifies the SSD UUID and VM disk path, then starts the pool
and NAT network if needed. NAT gives guests outbound Internet access through
the host; it does not assign them an IP from the home router. The **ip** command
uses libvirt DHCP leases, so it may show **unknown** for static guest addresses.

Inside each Windows guest, use **ipconfig**, **ping 1.1.1.1**, and
**nslookup example.com** to check the interface, routing and DNS. Set a password
on the Windows 7 VM before using it online. [Windows 7 is no longer supported](https://learn.microsoft.com/en-us/troubleshoot/windows-client/windows-7-eos-faq/windows-7-end-support-faq-general)
with regular security updates; connect it to the Internet only for the work
you need and keep its firewall enabled.

Older Windows 7 definitions may still use a VirtIO network adapter. In that
case, the attached **virtio-win.iso** contains **NetKVM/w7/amd64** and
**NetKVM/w7/x86**. In Device Manager, update the unrecognized Ethernet
Controller by browsing to the folder matching the guest's system type. Then
check **ipconfig /all** for a DHCP address from the configured NAT network.
If driver installation reports a signature error, inspect the error before
changing the VM's network model or Windows driver-signing settings.

## Remove lab definitions

~~~bash
scripts/teardown.sh
~~~

Teardown asks before removing each stopped VM definition, storage pool and the
project-owned NAT network. It refuses to force-stop running VMs, keeps qcow2
images and UEFI NVRAM, and never removes the shared **default** NAT network or
the host's **fstab** entry. Back up the SSD separately if the installed Windows
environments matter to you.
