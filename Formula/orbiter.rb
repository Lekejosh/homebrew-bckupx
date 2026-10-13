# Homebrew formula for Orbiter, the Concentric backup agent. It was
# bckupx-agent before the rename (0.1.46 and earlier); formula_renames.json
# moves an install of that over, and its install steps move the settings and
# data.
#
# The binaries are the same ones install.sh and the agent's self-updater use,
# from https://get.concentric.sh/<version>/; the sha256s below are those in
# that release's manifest.json. update-formula.sh rewrites the version and
# sha256s for a release - the agent's release workflow runs it on every
# stable tag.
class Orbiter < Formula
  desc "Concentric backup agent: scheduled database backups with restore verification"
  homepage "https://concentric.sh"
  version "0.1.46"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://get.concentric.sh/#{version}/agent-mac-arm-v#{version}"
      sha256 "61fef145e17ea13218292a20269394d20429cf52a6dbfecaea9bee6cf063fec7"
    end
    on_intel do
      url "https://get.concentric.sh/#{version}/agent-mac-intel-v#{version}"
      sha256 "7991603d4ac66766a58140334fac0005688a565130e08920ad19eed026211d3e"
    end
  end

  on_linux do
    on_arm do
      url "https://get.concentric.sh/#{version}/agent-linux-arm-v#{version}"
      sha256 "2a32558957562dcd9b0cb1978a27bf874481aaf2175eb24977e2e556b5361fca"
    end
    on_intel do
      url "https://get.concentric.sh/#{version}/agent-linux-v#{version}"
      sha256 "5aed764271a246cbb9e91fbf7db95a0203e0ba8e89d869647c2a88b89d25e5bf"
    end
  end

  def install
    # The download is the bare binary, named after its URL.
    bin.install Dir["agent-*"].first => "orbiter"
    # Its name before the rename.
    bin.install_symlink "orbiter" => "bckupx-agent"
  end

  # The license and master keys live in a settings file rather than in the
  # service definition, readable only by its owner. It's created once and
  # never overwritten, so upgrades keep the keys.
  post_install_steps do
    # From the bckupx-agent formula (before the rename): its settings move,
    # with the paths in them - never the keys - pointed at the new places,
    # and its data directory moves, with a link left at the old one: a local
    # storage target may point inside it.
    if_path_exists "bckupx/agent.env", base: :etc do
      unless_path_exists "orbiter/orbiter.env", base: :etc do
        mkdir_p "orbiter", base: :etc
        move "bckupx/agent.env", "orbiter/orbiter.env", source_base: :etc, target_base: :etc
        inreplace "orbiter/orbiter.env", "_DIRECTORY_PATH='{{var}}/bckupx'",
                  "_DIRECTORY_PATH='{{var}}/orbiter'", base: :etc, audit_result: false
        inreplace "orbiter/orbiter.env", "LOG_FILE='{{var}}/log/bckupx-agent.log'",
                  "LOG_FILE='{{var}}/log/orbiter.log'", base: :etc, audit_result: false
        inreplace "orbiter/orbiter.env", "brew services start bckupx-agent",
                  "brew services start orbiter", base: :etc, audit_result: false
      end
    end
    if_path_exists "bckupx", base: :var do
      unless_path_exists "orbiter", base: :var do
        move "bckupx", "orbiter", source_base: :var, target_base: :var
        symlink "orbiter", "bckupx", source_base: :var, target_base: :var
      end
    end

    mkdir_p "orbiter", base: :var
    mkdir_p "log", base: :var
    write_file "orbiter/orbiter.env", <<~EOS, base: :etc, overwrite: false
      # Orbiter settings, read by `brew services start orbiter`.
      # Fill in both keys (single quotes keep any character as-is), then
      # start the service. The master key decrypts your backups: save it
      # somewhere safe - it can't be recovered.
      LICENSE_KEY=''
      MASTER_ENCRYPTION_KEY=''

      # Where the agent keeps its database and logs - Homebrew's own folders,
      # so it runs as your user.
      MACOS_DIRECTORY_PATH='{{var}}/orbiter'
      LINUX_DIRECTORY_PATH='{{var}}/orbiter'
      LOG_FILE='{{var}}/log/orbiter.log'
    EOS
    set_permissions "orbiter/orbiter.env", "0600", base: :etc, recursive: false
  end

  # Restarted when it exits with an error. Updates come from `brew upgrade`:
  # the agent doesn't update itself when Homebrew installed it.
  service do
    run [opt_bin/"orbiter", "--env-file", etc/"orbiter/orbiter.env"]
    keep_alive successful_exit: false
    log_path var/"log/orbiter.stdout.log"
    error_log_path var/"log/orbiter.stdout.log"
  end

  def caveats
    s = <<~EOS
      To run the agent as a background service:
        1. Put your license key and master key in
             #{etc}/orbiter/orbiter.env
        2. brew services start orbiter

      Logs: #{var}/log/orbiter.log
      Upgrade with `brew upgrade orbiter`; the agent doesn't update itself
      when installed with Homebrew.

      Recover a backup on any machine with just your master key:
        orbiter recover --input <backup>.tar.gz.enc
    EOS
    # Moved from bckupx-agent: its service still runs under the old name,
    # which `brew services` no longer knows.
    if (var/"bckupx").symlink?
      stop = if OS.mac?
        "launchctl bootout gui/$(id -u)/sh.brew.bckupx-agent\n  " \
          "rm ~/Library/LaunchAgents/sh.brew.bckupx-agent.plist"
      else
        "systemctl --user disable --now sh.brew.bckupx-agent\n  " \
          "rm ~/.config/systemd/user/sh.brew.bckupx-agent.service"
      end
      s += <<~EOS

        Moved from bckupx-agent: its settings and data are now Orbiter's. If its
        service was running, swap it for Orbiter's:
          #{stop}
          brew services start orbiter
      EOS
    end
    s
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/orbiter --version")
  end
end
