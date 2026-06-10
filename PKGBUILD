# Maintainer: hody <hody@hody.tech>
# HelpWire Operator (Quick Connect) — Arch repackaging of the upstream portable tarball.
#
# Upstream ships only .deb / .rpm (thin downloaders) plus a self-contained portable
# .tar.gz. This package installs that portable tree into /opt and wires up the
# `helpwire://` URL scheme handler so clicking "Connect" in the HelpWire web app
# launches the desktop client. The bundled binary uses RUNPATH=$ORIGIN/../lib, so it
# locates its vendored Qt5 / OpenSSL 1.1 from /opt regardless of where it lives.

pkgname=helpwire-operator
pkgver=2.1.16.205
pkgrel=1
pkgdesc="HelpWire Operator — remote control / remote support desktop client (portable repackage)"
arch=('x86_64')
url="https://www.helpwire.app/"
license=('custom:proprietary')
# The app vendors Qt5, OpenSSL 1.1, boost, etc. under /opt/helpwire-operator/lib,
# so runtime deps are minimal — just desktop integration + ubiquitous X libs.
depends=('hicolor-icon-theme' 'xdg-utils' 'libxcb' 'fontconfig')
options=('!strip')  # vendored libs are already stripped; avoid touching them
source=("${pkgname}-${pkgver}.tar.gz::https://get.helpwire.app/downloads/operator/linux/helpwire-quick.tar.gz"
        "${pkgname}.desktop")
sha256sums=('83b02dbe99d5d6fe3fbda8fb77c970bcb6e765c992f766cbc7ad4df1f45f4eaf'
            'SKIP')

package() {
    cd "${srcdir}/helpwire-operator"

    # Self-contained app tree -> /opt
    install -d "${pkgdir}/opt/${pkgname}"
    cp -a bin lib plugins "${pkgdir}/opt/${pkgname}/"

    # Desktop launcher (absolute Exec, helpwire:// scheme handler)
    install -Dm644 "${srcdir}/${pkgname}.desktop" \
        "${pkgdir}/usr/share/applications/${pkgname}.desktop"

    # Icons into the hicolor theme so launchers + the browser handler prompt show them
    for size in 16 24 32 48 64 96 128 256; do
        install -Dm644 "desktop/helpwire-operator_${size}.png" \
            "${pkgdir}/usr/share/icons/hicolor/${size}x${size}/apps/${pkgname}.png"
    done

    # Convenience symlink on PATH
    install -d "${pkgdir}/usr/bin"
    ln -s "/opt/${pkgname}/bin/helpwire-operator" "${pkgdir}/usr/bin/helpwire-operator"
}
