#!/bin/sh
# Run from the Kanata folder: sudo sh install-kanata-autostart.sh ./kanata-native
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo 'Run this installer with sudo.' >&2
    exit 1
fi

source_dir=$(pwd -P)
case "$(uname -s)" in
    Darwin) platform=macos ;;
    Linux) platform=linux ;;
    *) echo 'This installer supports macOS and Linux.' >&2; exit 1 ;;
esac

binary=${1:-./kanata-native}
case "$binary" in
    /*) ;;
    *) binary="$source_dir/$binary" ;;
esac
binary_dir=$(CDPATH= cd -- "$(dirname -- "$binary")" && pwd -P)
if [ "$binary_dir" != "$source_dir" ]; then
    echo 'The native Kanata binary must be in the current directory.' >&2
    exit 1
fi
binary="$binary_dir/$(basename -- "$binary")"
if [ ! -f "$binary" ] || [ ! -x "$binary" ]; then
    echo 'Supply an executable Kanata binary built for this OS and CPU.' >&2
    exit 1
fi
if [ "$platform" = linux ] && ! command -v systemctl >/dev/null 2>&1; then
    echo 'This Linux installer requires systemd.' >&2
    exit 1
fi
KANATA_PLATFORM="$platform" "$binary" --check --no-wait --cfg "$source_dir/graphite-universal.kbd"

config="$source_dir/graphite-universal.kbd"
# XML escaping keeps spaces and XML punctuation valid in LaunchDaemon paths.
xml_escape() {
    printf '%s' "$1" | sed 's/\&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}
# Escape systemd specifiers, environment expansion, quotes, and backslashes.
unit_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/%/%%/g; s/\$/$$/g'
}

if [ "$platform" = macos ]; then
    install -d -m 755 /Library/LaunchDaemons
    touch /var/log/kanata.log
    chmod 644 /var/log/kanata.log
    chown root:wheel /var/log/kanata.log
    binary_xml=$(xml_escape "$binary")
    config_xml=$(xml_escape "$config")
    directory_xml=$(xml_escape "$source_dir")
    cat > /Library/LaunchDaemons/local.kanata.autostart.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.kanata.autostart</string>
  <key>ProgramArguments</key><array>
    <string>$binary_xml</string>
    <string>--cfg</string><string>$config_xml</string>
    <string>--no-wait</string>
  </array>
  <key>UserName</key><string>root</string>
  <key>EnvironmentVariables</key><dict>
    <key>KANATA_PLATFORM</key><string>macos</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict>
    <key>SuccessfulExit</key><false/>
  </dict>
  <key>WorkingDirectory</key><string>$directory_xml</string>
  <key>StandardOutPath</key><string>/var/log/kanata.log</string>
  <key>StandardErrorPath</key><string>/var/log/kanata.log</string>
</dict></plist>
PLIST
    chmod 644 /Library/LaunchDaemons/local.kanata.autostart.plist
    chown root:wheel /Library/LaunchDaemons/local.kanata.autostart.plist
    plutil -lint /Library/LaunchDaemons/local.kanata.autostart.plist
    "$binary" --macos-request-permissions >/dev/null 2>&1 || true
    launchctl bootout system/local.kanata.autostart >/dev/null 2>&1 || true
    launchctl bootstrap system /Library/LaunchDaemons/local.kanata.autostart.plist
    launchctl kickstart -k system/local.kanata.autostart
    echo 'Installed and started a root LaunchDaemon for all users.'
    echo 'Logs: /var/log/kanata.log'
    echo 'Kanata still requires its macOS keyboard driver and Input Monitoring/Accessibility permissions.'
else
    install -d -m 755 /etc/systemd/system /etc/modules-load.d
    printf '%s\n' uinput > /etc/modules-load.d/kanata.conf
    modprobe uinput
    binary_unit=$(unit_escape "$binary")
    config_unit=$(unit_escape "$config")
    # WorkingDirectory does not perform environment variable expansion.
    directory_unit=$(printf '%s' "$source_dir" | sed 's/\\/\\\\/g; s/"/\\"/g; s/%/%%/g')
    cat > /etc/systemd/system/kanata.service <<SERVICE
[Unit]
Description=Kanata keyboard remapper for all users
After=systemd-udev-trigger.service

[Service]
Type=simple
Environment=KANATA_PLATFORM=linux
WorkingDirectory="$directory_unit"
ExecStart="$binary_unit" --cfg "$config_unit" --no-wait
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
echo "Kanata will run directly from $source_dir"
