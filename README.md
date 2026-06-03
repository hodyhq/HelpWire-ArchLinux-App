# helpwire-arch-client

Arch Linux packaging for the **HelpWire Operator** remote-support desktop client.

HelpWire only ships `.deb` / `.rpm` (which are thin downloaders) plus a self-contained
portable `.tar.gz`. This repo wraps that portable build in a proper `PKGBUILD` so it
installs cleanly on Arch / CachyOS, registers the **`helpwire://` URL scheme handler**
(so clicking **Connect** in the HelpWire web app launches the desktop client), and is
tracked + removable by pacman.

## Install

```bash
git clone <link_to_repo>
cd helpwire-arch-client
makepkg -si
# one-time: make this app the handler for helpwire:// links
xdg-mime default helpwire-operator.desktop x-scheme-handler/helpwire
```

Then in the HelpWire web app, **Connect** will hand the `helpwire://…` URL to the
installed client.

### Or install a prebuilt release

Each release attaches a built `.pkg.tar.zst`:

```bash
sudo pacman -U <package-url-from-releases-page>
```

## How it works

| Concern | Detail |
|---|---|
| Install location | `/opt/helpwire-operator` (self-contained: vendored Qt5, OpenSSL 1.1, boost) |
| Lib resolution | Binary has `RUNPATH=$ORIGIN/../lib` — relocatable, no `LD_LIBRARY_PATH` wrapper |
| Launcher | `/usr/share/applications/helpwire-operator.desktop`, `Exec=env QT_QPA_PLATFORM=xcb …` |
| Wayland | Bundle has no Qt Wayland plugin → runs via XWayland (`xcb`), pinned in the launcher |
| Scheme handler | `MimeType=x-scheme-handler/helpwire;` → registered via `update-desktop-database` (pacman hook) + `xdg-mime default` |
| Icons | `desktop/*.png` → hicolor theme (8 sizes) |

## Updates

Upstream has no versioned download URL, so version detection uses the app's **own
auto-update manifest** — the endpoint the binary itself polls:

```
https://get.helpwire.app/downloads/operator/linux/update/settings.xml  ->  <current_version>
```

`scripts/check-update.sh` compares that to `pkgver` (exit `10` = update available).

CI (`.gitlab-ci.yml`) runs it on a **daily pipeline schedule**:

1. detect a newer `current_version`
2. download the latest tarball, **recompute** `sha256` (required — the URL is rolling)
3. bump `pkgver` + `sha256sums`, commit, push tag `vX.Y.Z.N`
4. the tag fires `build` → `release`, attaching the built `.pkg.tar.zst`
5. send a Matrix alert (optional) — GitLab release notifications also fire

### Manual update

```bash
git pull           # pulls the CI-bumped PKGBUILD
makepkg -si        # rebuild + upgrade
```

### Required CI/CD variables

| Variable | Purpose | Required |
|---|---|---|
| `GITLAB_PAT` | token w/ `write_repository` for the auto-bump push + tag | yes (for scheduled check) |
| `MATRIX_HS_URL` / `MATRIX_TOKEN` / `MATRIX_ROOM_ID` | chat alert on new version | optional |

The schedule is already created (**Build → Pipeline schedules**, daily 08:00 UTC, ref
`main`).

> [!note]
> **Maintenance touchpoint:** `GITLAB_PAT` is a **project access token** scoped to this
> repo (`write_repository` only), set to expire **2027-06-02**. When it expires the daily
> auto-bump job will start failing — mint a new project access token
> (Settings → Access Tokens) and update the `GITLAB_PAT` CI/CD variable. Nothing else
> needs touching.

## Uninstall

```bash
sudo pacman -R helpwire-operator
```

## License

Packaging scripts: MIT. The HelpWire Operator binary itself is proprietary, © Electronic
Team, Inc. — see <https://www.helpwire.app/>.
