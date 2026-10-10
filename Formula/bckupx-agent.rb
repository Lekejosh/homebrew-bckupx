# Homebrew formula for the bckupx agent.
#
# The binaries are the same ones install.sh and the agent's self-updater use,
# from https://agents.bckupx.com/<version>/; the sha256s below are those in
# that release's manifest.json. update-formula.sh rewrites the version and
# sha256s for a release - the agent's release workflow runs it on every
# stable tag.
class BckupxAgent < Formula
  desc "Backup agent for bckupx: scheduled database backups with restore verification"
  homepage "https://bckupx.com"
  version "0.1.41"
  license :cannot_represent

  on_macos do
    on_arm do
      url "https://agents.bckupx.com/#{version}/agent-mac-arm-v#{version}"
      sha256 "4c0877b37e58aa689801a2c2f6fc21e560f7b1ad3ba64f412671ed7c3922fd13"
    end
    on_intel do
      url "https://agents.bckupx.com/#{version}/agent-mac-intel-v#{version}"
      sha256 "8307666863408b8e027726a288dd09c82a2bb6fbb8f8761f3bd377d4edd179fe"
    end
  end

  on_linux do
    on_arm do
      url "https://agents.bckupx.com/#{version}/agent-linux-arm-v#{version}"
      sha256 "438f0fd5d5c32aace8e30a4d5020b7029f268e8c099c2e766ed68f6e5c7e71f2"
    end
    on_intel do
      url "https://agents.bckupx.com/#{version}/agent-linux-v#{version}"
      sha256 "582024af4469ffa19c22de06b0f6d0a421e150b093de0022633d5e7a99617ec4"
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
