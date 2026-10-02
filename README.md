# lab-kvm

Reusable QEMU/KVM lab for learning Windows system administration and networking.
The lab has one Windows Server 2008 SP2 VM and two Windows 7 VMs. VM images and ISOs
live on a dedicated ext4 filesystem. This host uses an internal NVMe partition;
the same UUID checks also support a removable USB SSD.

## Host requirements

- Linux host with KVM/VT-x or AMD-V, libvirt and a dedicated ext4 filesystem.
- Enough RAM for the host and the VMs you run together. The example sizes use
  2.5 GiB for the server and 1.5 GiB for each Windows 7 client.
- A NAT libvirt network for guest-to-guest, guest-to-host and Internet access.
  New labs use the project-owned **lab-kvm-nat** network. An existing lab may
  choose **default** in its local configuration.

The new network uses 192.168.233.0/24. If this overlaps a LAN or VPN route,
edit **networks/lab-nat.xml** before defining the network.

On this host, **config.local.sh** sets `LAB_NET=default`; all three existing
VMs use that NAT network on **192.168.122.0/24**. The project-owned
**lab-kvm-nat** network is a template for new labs and is not defined here.
Keep the local override when reusing these VMs: changing `LAB_NET` alone does
not move their NICs, and **lab-vm.sh start** checks for a match.
The host's **default** network now leases **192.168.122.100–254**. Addresses
**192.168.122.10–12** are reserved in the lab plan for manual guest setup.

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

- **LAB_FS_UUID**: UUID of the ext4 filesystem for VM storage. This is required
  before mounting, creating images or starting a VM.
- **LAB_DISK**: whole-disk /dev/disk/by-id/... path. It is used only for
  **setup-disk.sh --format**; leave it unset if the SSD is already formatted.
- **LAB_NET**: leave the default **lab-kvm-nat** for a new lab. Set **default**
  only if your existing VMs already use that NAT network.
- **SERVER_MAC**: optional MAC address for the server VM. Keep the old value
  when replacing that VM if its DHCP address should stay the same.

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
An internal partition normally mounts at boot. For a removable disk connected
later, run **scripts/mount-ssd.sh** as your normal user; it asks for sudo and
only mounts the configured filesystem. It does not accept formatting options.
The storage pool is not set to autostart, so the mount can be verified first. If an
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

Put the ISO files under **/mnt/lab-vms/ISOs/**. Required: **win-server-2008.iso**
and **virtio-win.iso**. Optional: **win7.iso**. See
[ISO-DOWNLOAD-GUIDE.md](ISO-DOWNLOAD-GUIDE.md).

~~~bash
scripts/create-vms.sh
virt-manager
~~~

Creation stops if the configured filesystem is not mounted. Existing qcow2
images and libvirt VM definitions are reused, so the installed VMs are retained.
New definitions are created in the shut-off state; start and install one VM at
a time with **scripts/lab-vm.sh start <vm-name>**. The
Windows 7 definitions are skipped if **win7.iso** is absent. New Windows 7
definitions use an emulated **e1000** network adapter so networking works
without a VirtIO network driver during setup. The Server 2008 definition uses
BIOS boot, a SATA system disk and an **e1000** adapter so setup can use built-in
drivers. If the Firefox ISO is present at creation, it is attached to the server.

| VM | Role | vCPU | RAM | Virtual disk |
| --- | --- | ---: | ---: | ---: |
| win-srv-01 | Windows Server 2008 SP2 x64 | 2 | 2.5 GiB | 35 GiB |
| win-w7-01 | Windows 7 client | 1 | 1.5 GiB | 20 GiB |
| win-w7-02 | Windows 7 client | 1 | 1.5 GiB | 20 GiB |

The helper limits starts to two lab VMs at a time. Shut down Windows inside
each VM before unplugging removable storage.

After Windows Server Setup has copied files and restarted, an attached installer
ISO can take the VM back to **Install now**. If this happens, use
`virsh domblklist win-srv-01` to identify the CD-ROM holding
`win-server-2008.iso`, then eject that target while the VM is running. In a new
definition made by this script, the target is `sdb`:

~~~bash
virsh change-media win-srv-01 sdb --eject --live --config
~~~

Then power off the VM and start it again. A reboot requested from the installer
may leave the existing setup session on screen. The Firefox ISO, when present,
can stay attached. The installed server should continue to the
Administrator password setup; enter that password inside the VM.

During Windows 7 setup, if no disk appears, choose **Load Driver** and browse
the attached **virtio-win.iso** to **viostor/w7/amd64** (or **x86** for 32-bit
Windows). This is the driver for the VirtIO system disk.

After installing a Windows 7 guest, shut it down and eject the Windows installer
ISO from the first CD-ROM (`sda`):

~~~bash
virsh change-media win-w7-01 sda --eject --config
~~~

Use `win-w7-02` for the second client. The VirtIO ISO in `sdb` can stay attached.
Ejecting the Windows installer ISO prevents a later boot from returning to
the installer; the installed qcow2 image does not need replacing.

`win-w7-02` needs its own Windows identity. Its qcow2 image on this host is
already partitioned and contains data; inspect the guest before resuming setup
or reinstalling it. Keep its existing disk image. This lab does not require
Sysprep or a copy of `win-w7-01`.

## Daily use and Internet check

With the lab filesystem mounted (connect a removable SSD first, if used):

~~~bash
scripts/lab-vm.sh list
scripts/lab-vm.sh start win-srv-01
scripts/lab-vm.sh console win-srv-01
scripts/lab-vm.sh ip
scripts/lab-vm.sh stop win-srv-01
~~~

The start command verifies the filesystem UUID and VM disk path, then starts
the pool and NAT network if needed. NAT gives guests outbound Internet through
the host; it does not assign them an IP from the home router. The **ip** command
uses libvirt DHCP leases, so it may show **unknown** for static guest addresses.
The optional **fstab** entry mounts at boot when the filesystem is present; it
does not mount a removable SSD automatically when plugged in after Ubuntu has
started. Run **scripts/mount-ssd.sh** after connecting one.

### IPv4 plan for manual guest setup on this host

| VM | Static IPv4 | Subnet mask | Gateway |
| --- | --- | --- | --- |
| win-srv-01 | 192.168.122.10 | 255.255.255.0 | 192.168.122.1 |
| win-w7-01 | 192.168.122.11 | 255.255.255.0 | 192.168.122.1 |
| win-w7-02 | 192.168.122.12 | 255.255.255.0 | 192.168.122.1 |

Set these addresses inside Windows. The libvirt **default** DHCP range is
**192.168.122.100–254**, so it will not lease any address in the table.
Before the server runs DNS, use **192.168.122.1** as DNS if Internet name
resolution is needed. If you configure the server as a DNS or Active Directory
server, set its own preferred DNS to **192.168.122.10**, configure a DNS
forwarder there, and set both clients' preferred DNS to **192.168.122.10**.
Do not point domain clients directly at **192.168.122.1** for domain lookups.
After changing each guest, verify with `ipconfig /all`, ping the gateway and
the other lab guests, then test DNS resolution. The `lab-vm.sh ip` command
reads DHCP leases and will not show manually assigned addresses.

Inside each Windows guest, use **ipconfig**, **ping 1.1.1.1**, and
**nslookup example.com** to check the interface, routing and DNS. Set a password
on the Windows 7 VM before using it online. [Windows 7 is no longer supported](https://learn.microsoft.com/en-us/troubleshoot/windows-client/windows-7-eos-faq/windows-7-end-support-faq-general)
with regular security updates; connect it to the Internet only for the work
you need and keep its firewall enabled.
The same applies to [Windows Server 2008](https://learn.microsoft.com/en-us/lifecycle/products/windows-server-2008),
whose extended support ended in January 2020.

Older Windows 7 definitions may still use a VirtIO network adapter. In that
case, the attached **virtio-win.iso** contains **NetKVM/w7/amd64** and
**NetKVM/w7/x86**. In Device Manager, update the unrecognized Ethernet
Controller by browsing to the folder matching the guest's system type. Then
check **ipconfig /all** for a DHCP address from the configured NAT network.
If driver installation reports a signature error, inspect the error before
changing the VM's network model or Windows driver-signing settings.

## Put Firefox installers in the Windows guests

Firefox 115 ESR is the final series supported on Windows 7; see
[Mozilla's Windows 7 support note](https://support.mozilla.org/en-US/kb/firefox-users-windows-7-8-and-81-moving-extended-support).
The example below uses the Vietnamese 32-bit and 64-bit installers for
**115.42.0esr**, released on September 29, 2026. See
[Mozilla's release notes](https://www.firefox.com/en-US/firefox/115.42.0/releasenotes/)
when choosing a version.

Run on the Linux host as your normal user. Install `xorriso` if needed.

~~~bash
version=115.42.0esr
mkdir -p "$HOME/Downloads/Firefox"/{win32,win64}
for arch in win32 win64; do
  curl -fL --retry 3 \
    -o "$HOME/Downloads/Firefox/$arch/Firefox Setup $version.exe" \
    "https://ftp.mozilla.org/pub/firefox/releases/$version/$arch/vi/Firefox%20Setup%20$version.exe"
done
~~~

For this exact version, the following SHA-256 values match
[Mozilla's SHA256SUMS](https://ftp.mozilla.org/pub/firefox/releases/115.42.0esr/SHA256SUMS):

~~~bash
(
  cd "$HOME/Downloads/Firefox" || exit
  printf '%s  %s\n' \
    ac2433ae5a275c1f10726ec025bea2891fe22c941ff9682b15ab81feb71078b0 \
    'win32/Firefox Setup 115.42.0esr.exe' \
    414794e16d582bf5b94a3725ce95b2b65e5b5e8ead733e90ae15def34d95d26a \
    'win64/Firefox Setup 115.42.0esr.exe' | sha256sum --check
)
~~~

Create the ISO once. The command leaves an existing ISO unchanged because an
ISO mounted by a VM must not be overwritten.

~~~bash
iso=/mnt/lab-vms/ISOs/Firefox-115.42.0esr.iso
if [ ! -e "$iso" ]; then
  xorriso -as mkisofs -J -R -V FIREFOX115 \
    -o "$iso" -graft-points "Firefox=$HOME/Downloads/Firefox"
fi
~~~

Check each VM's existing CD-ROMs before attaching the ISO:

~~~bash
export LIBVIRT_DEFAULT_URI=qemu:///system
for vm in win-srv-01 win-w7-01 win-w7-02; do
  virsh domblklist "$vm" --details
done
~~~

If `win-w7-01` is running and its first CD-ROM (`sda`) is empty after ejecting
the Windows installer, insert the ISO there:

~~~bash
iso=/mnt/lab-vms/ISOs/Firefox-115.42.0esr.iso
virsh change-media win-w7-01 sda --source "$iso" --insert --live --config
~~~

If `win-w7-01` is shut off, use `--config` without `--live` instead. For
`win-srv-01` and `win-w7-02` when shut off, add a third SATA CD-ROM (`sdc`)
without replacing their existing installation or VirtIO media:

~~~bash
for vm in win-srv-01 win-w7-02; do
  virsh attach-disk "$vm" "$iso" sdc --targetbus sata \
    --type cdrom --mode readonly --subdriver raw --config
done
~~~

`--config` makes the media available at the next boot; `--live --config` also
changes a running VM immediately. Libvirt cannot hotplug a new SATA CD-ROM into
a running VM, so use an existing empty CD-ROM or shut the guest down first.
If the ISO is already listed for a VM, skip the attach command for that VM.
Verify with `virsh domblklist <vm-name> --details` and, for saved settings,
`virsh domblklist <vm-name> --inactive --details`.

In Windows Explorer, open the **FIREFOX115** CD-ROM and choose
`Firefox\win32` or `Firefox\win64` to match the guest's **System type**.
The ISO is read-only; copy the installer to `C:` if it must remain in the VM
after the ISO is ejected.

## Remove lab definitions

~~~bash
scripts/teardown.sh
~~~

Teardown asks before removing each stopped VM definition, storage pool and the
project-owned NAT network. It refuses to force-stop running VMs, keeps qcow2
images and UEFI NVRAM, and never removes the shared **default** NAT network or
the host's **fstab** entry. Back up the SSD separately if the installed Windows
environments matter to you.
