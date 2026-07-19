# Homebrew formula for the bckupx agent CLI/binary.
#
# This repo is the tap itself (Homebrew requires a repo literally named
# `homebrew-<name>` - see README.md for the one-time publish steps and
# ../agent/packaging/DISTRIBUTION_SETUP.md for the wider release checklist).
#
# On every agent release, run update-formula.sh <version> from the repo
# root to recompute the sha256s below against that release's GitHub assets
# and bump `version`, then commit + push.
class BckupxAgent < Formula
  desc "Self-hosted backup agent for bckupx - scheduled DB backups with restore verification"
  homepage "https://bckupx.com"
  version "0.1.0"
  license "Proprietary"

  on_macos do
    on_arm do
      url "https://github.com/Lekejosh/backupx-agent/releases/download/v#{version}/bckupx-agent-macos-aarch64.tar.gz"
      sha256 "REPLACE_WITH_SHA256" # see update-formula.sh
    end
    on_intel do
      url "https://github.com/Lekejosh/backupx-agent/releases/download/v#{version}/bckupx-agent-macos-x86_64.tar.gz"
      sha256 "REPLACE_WITH_SHA256"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/Lekejosh/backupx-agent/releases/download/v#{version}/bckupx-agent-linux-aarch64.tar.gz"
      sha256 "REPLACE_WITH_SHA256"
    end
    on_intel do
      url "https://github.com/Lekejosh/backupx-agent/releases/download/v#{version}/bckupx-agent-linux-x86_64.tar.gz"
      sha256 "REPLACE_WITH_SHA256"
    end
  end

  def install
    bin.install "agent" => "bckupx-agent"
  end

  # No `service do` block on purpose: the agent needs LICENSE_KEY and
  # MASTER_ENCRYPTION_KEY before it can run at all (no safe defaults - see
  # agent/scripts/install.sh), so auto-starting it via `brew services start`
  # right after install would just crash-loop unconfigured. Use
  # agents.bckupx.com/install.sh for a fully managed background service
  # (systemd/launchd, auto-restart, starts on boot); this formula is for
  # getting the `bckupx-agent` binary itself onto PATH - e.g. for the
  # offline `decrypt-backup`/`rotate-master-key` maintenance commands, which
  # don't need a running service at all.
  def caveats
    <<~EOS
      This installs the bckupx-agent binary only - it does not start or
      manage a background service. For a full managed install (systemd on
      Linux, launchd on macOS, auto-restart, starts on boot), use:

        curl -fsSL https://agents.bckupx.com/install.sh | sudo bash

      To run the agent directly instead:

        LICENSE_KEY=... MASTER_ENCRYPTION_KEY=... bckupx-agent
    EOS
  end

  test do
    assert_predicate bin/"bckupx-agent", :exist?
    assert_predicate bin/"bckupx-agent", :executable?
  end
end
