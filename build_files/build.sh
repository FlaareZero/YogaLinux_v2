#!/bin/bash

set -ouex pipefail

## DNF5 Speedup
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

## System apps
dnf -y install libvirt virt-manager qemu-kvm flatpak-builder wlr-randr iotop sysstat lxqt-openssh-askpass lxpolkit

# User apps
dnf -y install nautilus mpv grim

# Brave Origin Beta
curl -fsSLo /etc/yum.repos.d/brave-browser-beta.repo \
  https://brave-browser-rpm-beta.s3.brave.com/brave-browser-beta.repo

dnf install -y brave-origin-beta

# OBS and fully-featured ffmpeg with nonfree components from rpm fusion
dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf -y install ffmpeg x264-libs obs-studio obs-studio-plugin-x264 --allowerasing

# Nautilus open any terminal extension
curl -Lo /etc/yum.repos.d/nautilus-open-any-terminal.repo \
  https://copr.fedorainfracloud.org/coprs/monkeygold/nautilus-open-any-terminal/repo/fedora-$(rpm -E %fedora)/monkeygold-nautilus-open-any-terminal-fedora-$(rpm -E %fedora).repo
dnf install -y nautilus-open-any-terminal
glib-compile-schemas /usr/share/glib-2.0/schemas
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal alacritty


# Install Niri 
dnf -y install niri 

# # Install Noctalia shell
# curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo -o /etc/yum.repos.d/terra.repo
# dnf -y install terra-release
# dnf -y install noctalia-shell 
# # ABILITARE LE NOTIFICHE: systemctl --user enable --now swaync.service

# Install Dank Linux shell
sudo curl --output-dir "/etc/yum.repos.d/" \
  --remote-name "https://copr.fedorainfracloud.org/coprs/avengemedia/dms/repo/fedora-$(rpm -E %fedora)/avengemedia-dms-fedora-$(rpm -E %fedora).repo"
dnf -y install quickshell dms greetd dms-greeter --allowerasing 
#
# Install greetd login manager with dank configuration (still needs some work)
mkdir -p /etc/greetd/
cat > /etc/greetd/config.toml << EOF
[terminal]
vt = 1
[default_session]
user = "greeter"
command = "dms-greeter --command niri"
EOF
rm -f /etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service
systemctl enable --force greetd.service

mkdir -p /etc/skel/.config/systemd/user/graphical-session.target.wants
ln -s /usr/lib/systemd/user/dms.service /etc/skel/.config/systemd/user/graphical-session.target.wants/
mkdir -p /etc/skel/.config/niri/
cp -rf /ctx/dot_config/niri/config.kdl /etc/skel/.config/niri/

# DEV packages
# cargo evtest git input-remapper libevdev-devel libinput-utils python3-devel

# Bluetooth LDAC config
mkdir -p /etc/skel/.config/wireplumber/wireplumber.conf.d/
cat > /etc/skel/.config/wireplumber/wireplumber.conf.d/bluetooth-ldac.conf << 'EOF'
monitor.bluez.properties = {
    # Fix cuffie BT da CachyOS
    ["bluez5.ldac-hq-mode"] = "auto"
}
EOF

# dnf -y install bitwarden-cli 

# Pre-configure Flathub remote on first boot
cat > /etc/systemd/system/flathub-setup.service << EOF
[Unit]
Description=Add Flathub Flatpak remote
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/flatpak/repo/flathub.trustedkeys.gpg

[Service]
Type=oneshot
ExecStart=flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable flathub-setup.service

#### Enable podman

systemctl enable podman.socket

# Disable Origami tips

sudo mv /etc/profile.d/origami-aliases.sh /etc/profile.d/origami-aliases.sh.bak

# Remove COSMIC shell and waybar
dnf -y remove cosmic-comp cosmic-initial-setup cosmic-settings cosmic-settings-daemon cosmic-store waybar cosmic-text cosmic-files cosmic-screenshot cosmic-camera cosmic-player


## CLEAN UP
# Clean up dnf cache to reduce image size
dnf5 -y clean all
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
