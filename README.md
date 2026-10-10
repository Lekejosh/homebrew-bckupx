# homebrew-bckupx

Homebrew tap for the [bckupx](https://bckupx.com) backup agent.

```
brew install lekejosh/bckupx/bckupx-agent
```

## Running it as a service

1. Put your license key (from the portal: Agents -> Add agent) and your
   master key in `$(brew --prefix)/etc/bckupx/agent.env` - created on
   install, readable only by you, and kept across upgrades.
2. `brew services start bckupx-agent`

It keeps its database in `$(brew --prefix)/var/bckupx` and logs to
`$(brew --prefix)/var/log/bckupx-agent.log`, and restarts if it stops with an
error. Update with `brew upgrade bckupx-agent` - the agent doesn't update
itself when Homebrew installed it.

Your master key decrypts your backups and can't be recovered: save it
somewhere safe. With it, `bckupx-agent recover --input <backup>.tar.gz.enc`
decrypts any backup on any machine.

## Releases

`Formula/bckupx-agent.rb` downloads the agent binaries from
`agents.bckupx.com`, checked against each release's `manifest.json`. The
agent's release workflow runs `./update-formula.sh <version>` and pushes the
result on every stable release; to do it by hand:

```
./update-formula.sh 0.1.42
git commit -am "bckupx-agent 0.1.42" && git push
```
