#!/bin/sh
# Usage: sudo sh install-kanata-autostart.sh /path/to/native/kanata
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo 'Run this installer with sudo.' >&2
    exit 1
fi

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case "$(uname -s)" in
    Darwin) platform=macos ;;
    Linux) platform=linux ;;
    *) echo 'This installer supports macOS and Linux.' >&2; exit 1 ;;
esac

binary=${1:-}
if [ -z "$binary" ]; then
    echo 'Usage: sudo sh install-kanata-autostart.sh /path/to/native/kanata' >&2
    exit 1
fi
if [ ! -f "$binary" ] || [ ! -x "$binary" ]; then
    echo 'Supply an executable Kanata binary built for this OS and CPU.' >&2
    exit 1
fi
if [ "$platform" = linux ] && ! command -v systemctl >/dev/null 2>&1; then
    echo 'This Linux installer requires systemd.' >&2
    exit 1
fi
KANATA_PLATFORM="$platform" "$binary" --check --no-wait --cfg "$source_dir/graphite-universal.kbd"

install_dir=/usr/local/lib/kanata
install -d -m 755 "$install_dir"
install -m 755 "$binary" "$install_dir/kanata"
install -m 644 "$source_dir/graphite-universal.kbd" "$install_dir/graphite-universal.kbd"

if [ "$platform" = macos ]; then
    install -d -m 755 /Library/LaunchDaemons
    cat > /Library/LaunchDaemons/local.kanata.autostart.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.kanata.autostart</string>
  <key>ProgramArguments</key><array>
    <string>/usr/local/lib/kanata/kanata</string>
    <string>--cfg</string><string>/usr/local/lib/kanata/graphite-universal.kbd</string>
    <string>--no-wait</string>
  </array>
  <key>EnvironmentVariables</key><dict>
    <key>KANATA_PLATFORM</key><string>macos</string>
  </dict>
  <key>RunAtLoad</key><true/>
</dict></plist>
PLIST
    chmod 644 /Library/LaunchDaemons/local.kanata.autostart.plist
    chown root:wheel /Library/LaunchDaemons/local.kanata.autostart.plist
    plutil -lint /Library/LaunchDaemons/local.kanata.autostart.plist
    echo 'Installed a root LaunchDaemon for all users. Reboot to start.'
    echo 'Kanata still requires its macOS keyboard driver and privacy permissions.'
else
    install -d -m 755 /etc/systemd/system /etc/modules-load.d
    printf '%s\n' uinput > /etc/modules-load.d/kanata.conf
    modprobe uinput
    cat > /etc/systemd/system/kanata.service <<'SERVICE'
[Unit]
Description=Kanata keyboard remapper for all users
After=systemd-udev-trigger.service

[Service]
Type=simple
Environment=KANATA_PLATFORM=linux
ExecStart=/usr/local/lib/kanata/kanata --cfg /usr/local/lib/kanata/graphite-universal.kbd --no-wait
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE
    chmod 644 /etc/systemd/system/kanata.service
    systemctl daemon-reload
    systemctl enable kanata.service
    echo 'Installed a root systemd service for all users. Reboot to start.'
fi
echo "Installed config: $install_dir/graphite-universal.kbd"
