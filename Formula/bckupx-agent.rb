# Homebrew formula for the Concentric agent (formerly bckupx).
#
# The binaries are the same ones install.sh and the agent's self-updater use,
# from https://agents.bckupx.com/<version>/; the sha256s below are those in
# that release's manifest.json. update-formula.sh rewrites the version and
# sha256s for a release - the agent's release workflow runs it on every
# stable tag.
class BckupxAgent < Formula
  desc "Concentric backup agent: scheduled database backups with restore verification"
  homepage "https://bckupx.com"
  version "0.1.43"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://agents.bckupx.com/#{version}/agent-mac-arm-v#{version}"
      sha256 "68f294936484beef9456333774a664292d2cfb6c49936f45aa1d5796aebe38c2"
    end
    on_intel do
      url "https://agents.bckupx.com/#{version}/agent-mac-intel-v#{version}"
      sha256 "1bb8980194b2f803d6e5e96834bb80d4f8322a6e3fe2dc664d2f231a23db079f"
    end
  end

  on_linux do
    on_arm do
      url "https://agents.bckupx.com/#{version}/agent-linux-arm-v#{version}"
      sha256 "1eb1c8fd7657ae5ffa182a7599291fc2bfac49648cea7ab06be26e4941c026f8"
    end
    on_intel do
      url "https://agents.bckupx.com/#{version}/agent-linux-v#{version}"
      sha256 "c6338c7b7c3b22c10b861de9248a0f8157c9348eaafa7441726bb4a690f4ed72"
    end
  end

  def install
    # The download is the bare binary, named after its URL.
    bin.install Dir["agent-*"].first => "bckupx-agent"
  end

  # The license and master keys live in this file rather than in the service
  # definition, readable only by its owner. It's created once and never
  # overwritten, so upgrades keep the keys.
  def post_install
    (var/"bckupx").mkpath
    (var/"log").mkpath
    (etc/"bckupx").mkpath
    env = etc/"bckupx/agent.env"
    return if env.exist?

    env.write <<~EOS
      # bckupx agent settings, read by `brew services start bckupx-agent`.
      # Fill in both keys (single quotes keep any character as-is), then
      # start the service. The master key decrypts your backups: save it
      # somewhere safe - it can't be recovered.
      LICENSE_KEY=''
      MASTER_ENCRYPTION_KEY=''

      # Where the agent keeps its database and logs - Homebrew's own folders,
      # so it runs as your user.
      MACOS_DIRECTORY_PATH='#{var}/bckupx'
      LINUX_DIRECTORY_PATH='#{var}/bckupx'
      LOG_FILE='#{var}/log/bckupx-agent.log'
    EOS
    env.chmod 0600
  end

  # Restarted when it exits with an error. Updates come from `brew upgrade`:
  # the agent doesn't update itself when Homebrew installed it.
  service do
    run [opt_bin/"bckupx-agent", "--env-file", etc/"bckupx/agent.env"]
    keep_alive successful_exit: false
    log_path var/"log/bckupx-agent.stdout.log"
    error_log_path var/"log/bckupx-agent.stdout.log"
  end

  def caveats
    <<~EOS
      To run the agent as a background service:
        1. Put your license key and master key in
             #{etc}/bckupx/agent.env
        2. brew services start bckupx-agent

      Logs: #{var}/log/bckupx-agent.log
      Upgrade with `brew upgrade bckupx-agent`; the agent doesn't update
      itself when installed with Homebrew.

      Recover a backup on any machine with just your master key:
        bckupx-agent recover --input <backup>.tar.gz.enc
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bckupx-agent --version")
  end
end
