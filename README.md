# HelpWire Operator (Arch Linux)

Arch Linux packaging for the **HelpWire Operator** remote-support desktop client.

HelpWire ships `.deb` / `.rpm` plus a self-contained portable `.tar.gz`. This repo wraps
that portable build in a proper `PKGBUILD` so it installs cleanly on Arch and CachyOS,
registers the **`helpwire://` URL scheme handler** (so clicking **Connect** in the
HelpWire web app launches the desktop client), and is tracked and removable by pacman.

Packages are GPG-signed, so the repo runs under pacman's `SigLevel = Required`.

## Install

### From the custom pacman repo (recommended, signed, auto-updates)

One command to import the signing key, add the repo, and install (idempotent):

```bash
sudo bash -c '
set -e
curl -fsSL https://github.com/hodyhq/HelpWire-ArchLinux-App/releases/download/repo/helpwire.pub | pacman-key --add -
pacman-key --lsign-key 44CF4CEC2ABAE2B76FE824BD00CBCF76ABAAEB97
grep -q "^\[helpwire\]" /etc/pacman.conf || printf "\n[helpwire]\nSigLevel = Required\nServer = https://github.com/hodyhq/HelpWire-ArchLinux-App/releases/download/repo\n" >> /etc/pacman.conf
pacman -Sy --needed helpwire-operator
'
```

After that, your normal `sudo pacman -Syu` keeps it current.

Or do it by hand:

```bash
# 1. trust the repo signing key (ed25519, fingerprint 44CF4CEC2ABAE2B76FE824BD00CBCF76ABAAEB97)
curl -fsSL https://github.com/hodyhq/HelpWire-ArchLinux-App/releases/download/repo/helpwire.pub \
  | sudo pacman-key --add -
sudo pacman-key --lsign-key 44CF4CEC2ABAE2B76FE824BD00CBCF76ABAAEB97
```

Then append to `/etc/pacman.conf`:

```ini
[helpwire]
SigLevel = Required
Server = https://github.com/hodyhq/HelpWire-ArchLinux-App/releases/download/repo
```

```bash
sudo pacman -Sy helpwire-operator
```

### Build from source

```bash
git clone <link_to_repo>
cd helpwire-operator && makepkg -si
```

### AUR

AUR registration is currently closed. When it reopens, the package publishes to the AUR
automatically (set the `AUR_SSH_PRIVATE_KEY` secret), and `yay -S helpwire-operator` will
work. Until then, use the custom repo above.

### One-time: register the URL handler

```bash
xdg-mime default helpwire-operator.desktop x-scheme-handler/helpwire
```

Then in the HelpWire web app, **Connect** hands the `helpwire://...` URL to the client.

## How it works

| Concern | Detail |
|---|---|
| Install location | `/opt/helpwire-operator` (self-contained: vendored Qt5, OpenSSL 1.1, boost) |
| Lib resolution | Binary has `RUNPATH=$ORIGIN/../lib`, relocatable, no `LD_LIBRARY_PATH` wrapper |
| Launcher | `/usr/share/applications/helpwire-operator.desktop`, `Exec=env QT_QPA_PLATFORM=xcb ...` |
| Wayland | Bundle has no Qt Wayland plugin, so it runs via XWayland (`xcb`), pinned in the launcher |
| Scheme handler | `MimeType=x-scheme-handler/helpwire;`, registered via the `update-desktop-database` pacman hook plus `xdg-mime default` |
| Signing | Every package and the repo DB are GPG-signed (ed25519); `SigLevel = Required` |
| Icons | hicolor theme, 8 sizes |

## Staying current (automatic)

Upstream uses one rolling, unversioned download URL, so the real version comes from the
app's own auto-update manifest (the endpoint the binary itself polls):

```
https://get.helpwire.app/downloads/operator/linux/update/settings.xml  ->  <current_version>
```

A GitHub Actions workflow (`.github/workflows/update.yml`) runs daily and on demand:

1. read `<current_version>`; stop if it matches the current `pkgver`
2. recompute the tarball `sha256` (required, the URL is rolling) and bump the PKGBUILD
3. commit the bump back here
4. build the package in an Arch container, **GPG-sign** it and the DB, and refresh the
   custom pacman repo (the `repo` release) plus cut an official `vX.Y.Z.N` release
5. when the `AUR_SSH_PRIVATE_KEY` secret is set, also push to the AUR

Signing uses the `GPG_PRIVATE_KEY` repo secret; its public half is `helpwire.pub`.
`scripts/check-update.sh` is the same version check you can run by hand.

## Uninstall

```bash
sudo pacman -R helpwire-operator
```

To stop receiving updates, also remove the `[helpwire]` block from `/etc/pacman.conf`.

## License

Packaging scripts: MIT. The HelpWire Operator binary itself is proprietary, (c) Electronic
Team, Inc. See <https://www.helpwire.app/>.
