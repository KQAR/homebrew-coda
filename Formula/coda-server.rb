# coda-server — the macOS host daemon, for a machine with no graphical session.
#
# Binary-only, because coda is closed source. That is why this tap exists at all: a
# third-party tap may ship a prebuilt archive, homebrew-core may not. The tarball is cut by
# `server/release.sh` in the app repo and its version is `Version.current` — the same string
# the daemon announces in `hello`, so this formula cannot claim a version the daemon denies.
#
# `Casks/coda.rb` next door ships the same daemon as an app in the menu bar, and that app
# carries this binary inside it. A machine wants one or the other: one UDP port, and a second
# listener would share it rather than refuse it.
class CodaServer < Formula
  desc "Host daemon for coda: drive the coding agents on your Mac from your phone"
  homepage "https://github.com/KQAR/homebrew-coda"
  url "https://github.com/KQAR/homebrew-coda/releases/download/v0.0.5/coda-server-0.0.5-arm64.tar.gz"
  sha256 "7ddfcdd225e37c5f5a462e88da37f6941a44cc71805cc8a3c676a231972f695c"

  # Apple silicon only. The tarball carries one slice; an x86_64 one that nothing here can
  # execute would be a claim rather than support (`server/release.sh`), and without this a
  # `brew install` on an Intel Mac lands a binary that cannot exec.
  depends_on arch: :arm64
  # Package.swift's floor: Network.framework's QUIC is what carries the wire, and the daemon
  # is macOS-only by measurement rather than preference (ARCHITECTURE.md).
  depends_on macos: :tahoe

  # Herdr and Orca are *discovered* at runtime and never launched by coda — a machine with
  # neither still pairs and still answers. So neither is a dependency here.

  def install
    bin.install "coda-server"
  end

  service do
    run [opt_bin/"coda-server", "run"]
    keep_alive true
    log_path var/"log/coda-server.log"
    error_log_path var/"log/coda-server.log"
    # Never root. The daemon reads this user's Keychain, ~/.coda and the agent settings
    # under ~/.claude; as root it would read the wrong ones and write files the user cannot.
    require_root false
  end

  def caveats
    <<~EOS
      Run it at login, and pair a phone:

        brew services start coda-server
        coda-server pair            # prints the QR the app scans

      It listens on udp/51820 and attaches to the Herdr and Orca sessions you already run —
      it never starts a session of its own. Its state, including the host key, is in ~/.coda.

      `coda-server install-hooks` is what makes a phone learn that an agent is waiting rather
      than finding out on the next poll. It shows you the change to ~/.claude/settings.json
      before writing it.

      Do not also install the coda app: it carries this binary inside it, and two listeners
      would share udp/51820 rather than refuse it.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/coda-server --help")
  end
end
