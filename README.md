# Graphite Universal installation

This guide uses Kanata v1.12.0, the version targeted by this configuration.
Official repository: https://github.com/jtroo/kanata
Official release: https://github.com/jtroo/kanata/releases/tag/v1.12.0
Newer releases: https://github.com/jtroo/kanata/releases

Download compiled binaries from the release's Assets section. The GitHub
"Source code" archives contain source, not ready-to-run executables.
Keep graphite-universal.kbd and the relevant installer from this folder together.
They are custom files; downloading upstream Kanata will not provide them.
Keep your operating system's keyboard input layout set to US QWERTY.

## Windows (Intel/AMD x64)

1. Download windows-binaries-x64.zip:
   https://github.com/jtroo/kanata/releases/download/v1.12.0/windows-binaries-x64.zip
2. Right-click the ZIP and select Extract All. Alternatively, in PowerShell:

   Expand-Archive -LiteralPath "$HOME\Downloads\windows-binaries-x64.zip" -DestinationPath "$HOME\Documents\kanata-download"

3. Copy kanata_windows_gui_winIOv2_x64.exe from the extracted files into the
   folder containing graphite-universal.kbd and install-kanata-autostart.ps1.
   This variant does not require the Interception driver or the passthru DLL.
4. Open PowerShell as administrator, change to that folder, and run:

   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-kanata-autostart.ps1

5. Sign out and sign back in. Kanata starts at each user's login.

The installer uses the executable and config in your current directory and
adds Kanata.vbs to the all-users Startup folder. It sets KANATA_PLATFORM=windows.
All users must have read/execute access to this directory.
Windows Script Host must be enabled for the VBS launcher to run.

For a manual test from the source folder, run:

   $env:KANATA_PLATFORM = 'windows'
   .\kanata_windows_gui_winIOv2_x64.exe --cfg .\graphite-universal.kbd

Close that instance before testing automatic startup. The supplied Windows
installer uses the x64 filename; ARM64 Windows requires an ARM64 release binary
and a corresponding filename change in the installer.

## macOS

1. Download the macOS binary ZIP for your CPU:

   Apple Silicon:
   https://github.com/jtroo/kanata/releases/download/v1.12.0/macos-binaries-arm64.zip

   Intel:
   https://github.com/jtroo/kanata/releases/download/v1.12.0/macos-binaries-x64.zip

   Double-click the ZIP in Finder, or extract it in Terminal:

   unzip "$HOME/Downloads/macos-binaries-arm64.zip" -d "$HOME/Downloads/kanata-extracted"

   For Intel, substitute macos-binaries-x64.zip. Find the native executable in
   the extracted folder and copy it beside the config and shell installer,
   naming that copy kanata-native.
2. Install the required Karabiner VirtualHIDDevice driver. Kanata v1.12.0 uses
   driver v6.2.0; newer Kanata versions may require a different driver:
   https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/tag/v6.2.0
   Run the package installer, then open System Settings > General > Login Items
   & Extensions > Driver Extensions and enable
   org.pqrs.Karabiner-DriverKit-VirtualHIDDevice. A reboot may be required
   after activating the driver.
3. Ensure the VirtualHIDDevice daemon runs at boot. If Karabiner-Elements is
   installed, it normally manages the daemon. If you installed only the
   standalone driver, follow the upstream standalone daemon setup:
   https://github.com/jtroo/kanata/blob/main/docs/setup-macos.md
   You can check for the daemon with:

   sudo launchctl list | grep org.pqrs

4. In Terminal, change to the folder containing the three custom files and run:

   chmod +x ./kanata-native
   sudo sh ./install-kanata-autostart.sh ./kanata-native

5. Give the native Kanata executable in your current directory Input Monitoring
   and Accessibility access in System Settings > Privacy & Security. The
   installer asks macOS to show/register the Accessibility permission prompt
   when supported. Use Command+Shift+G in the file picker to reach this path.
6. After granting privacy permissions, restart Kanata:

   sudo launchctl kickstart -k system/local.kanata.autostart

   Reboot instead if you just activated the driver.

The installer sets KANATA_PLATFORM=macos and creates
/Library/LaunchDaemons/local.kanata.autostart.plist. Kanata runs as root at boot
and serves users across logins. It does not create a separate instance per user.
The installer starts or restarts the LaunchDaemon immediately; after reboot it
starts automatically. Check its state and logs with:

   sudo launchctl print system/local.kanata.autostart
   tail -f /var/log/kanata.log

## Linux (systemd)

1. For x64 Linux, download linux-binaries-x64.zip:
   https://github.com/jtroo/kanata/releases/download/v1.12.0/linux-binaries-x64.zip
2. Extract it using your file manager, or run:

   unzip "$HOME/Downloads/linux-binaries-x64.zip" -d "$HOME/Downloads/kanata-extracted"

   Install your distribution's unzip package if that command is unavailable.
   Copy the native executable beside the config and shell installer, naming
   that copy kanata-native. For another CPU architecture, use an appropriate
   official binary if available, or build Kanata from the original repository.
3. From that folder, run:

   chmod +x ./kanata-native
   sudo sh ./install-kanata-autostart.sh ./kanata-native

4. Reboot, then check:

   systemctl status kanata.service
   journalctl -u kanata.service -b

The installer sets KANATA_PLATFORM=linux, loads uinput, and enables a root
systemd service at boot. One instance remaps the machine's keyboard for all
users. This installer requires systemd and kernel support for uinput.
Because it runs as root, per-user input/uinput group membership is unnecessary.
Upstream Linux setup: https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md

## Configuration, updates, and stopping

Graphite is the startup layout. Hold physical Caps Lock and press physical Q
to select QWERTY, or physical G to select Graphite. Tap Caps Lock for Caps Lock.
Hold physical Left Ctrl + Space + Escape together for Kanata's emergency exit.

Windows text navigation works in both Graphite and QWERTY:

| Physical modifier | Left / Right | Up / Down |
| --- | --- | --- |
| Left Win (Option) | Ctrl+Left / Ctrl+Right: words | Ctrl+Up / Ctrl+Down: paragraphs |
| Left Alt (Command) | Home / End: line edges | Ctrl+Home / Ctrl+End: document edges |

Add either Shift key to select text while moving. These mappings apply globally;
the focused application determines the exact navigation behavior. macOS keeps
native Option/Command navigation. Right-side modifiers and Linux remain native.

Windows Backspace editing also works in both layouts:

- Physical Left Win (Option) + Backspace sends Ctrl+Backspace to delete the previous word.
- Physical Left Alt (Command) + Backspace sends Shift+Home, then Backspace to delete to the line start.

These shortcuts depend on the focused application's text editing behavior.

Windows screenshot shortcuts (physical Left Alt acts as Command):

- Command+Shift+3: Win+Print Screen, save a full-screen screenshot.
- Command+Shift+4: Win+Shift+S, open area screenshot selection.
- Command+Shift+5: Win+Shift+R, open recording selection on supported Windows 11 Snipping Tool versions.

Either Shift key works. Unshifted Command+3/4/5 still sends Ctrl+3/4/5.
Command+Shift+5 opens recording controls rather than macOS's combined toolbar.
Official Windows capture guide: https://support.microsoft.com/en-us/windows/apps/use-snipping-tool-to-capture-screenshots

Windows Command/Option activate shortcut layers without holding Alt, so editing
shortcuts do not restore Alt and activate the menu bar on modifier release.
Hold either left emulated modifier and tap Tab to cycle windows; Alt is activated
for task switching and released when the modifier is released. Unmapped keys
on these layers type normally. Use Right Alt for native Alt shortcuts.

The installers use the executable and config directly from the directory you
are in when running the installer. They only create the OS startup/service
entries (and Linux's uinput module configuration). Keep the directory in place
and available at login/boot. If you move it, rerun the installer from its new
location. Edit graphite-universal.kbd here, then restart Kanata to apply changes.
On Windows, quit Kanata before replacing the executable, then sign in again.
On macOS/Linux, restart after updating the installed files:

   # macOS, once the service has been loaded by a reboot
   sudo launchctl kickstart -k system/local.kanata.autostart

   # Linux
   sudo systemctl restart kanata.service

To disable automatic startup:

   Windows: delete Kanata.vbs from the folder opened by Win+R > shell:common startup,
            using administrator permission, and quit the running tray application.
   macOS:   sudo launchctl bootout system/local.kanata.autostart
            sudo rm /Library/LaunchDaemons/local.kanata.autostart.plist
            sudo rm /var/log/kanata.log
   Linux:   sudo systemctl disable --now kanata.service

These steps disable Kanata startup; they leave the installed executable/config.
Linux restarts on failure, so use systemctl stop kanata.service to stop it reliably.
Do not run a manual instance while the installed service is active.

Validation: the config parses with the bundled Windows Kanata 1.12.0 binary for
all three environment settings. Native macOS/Linux installation and keyboard
behavior have not been tested in this Windows workspace. Each Unix installer
checks the config with your supplied native binary before installing it.
