# homebrew-concentric

Homebrew tap for [Orbiter](https://concentric.sh), the Concentric backup agent.

```
brew trust lekejosh/concentric
brew install lekejosh/concentric/orbiter
```

(Homebrew only loads formulae from taps you've trusted.)

## Running it as a service

1. Put your license key (from the portal: Agents -> Add agent) and your
   master key in `$(brew --prefix)/etc/orbiter/orbiter.env` - created on
   install, readable only by you, and kept across upgrades.
2. `brew services start orbiter`

It keeps its database in `$(brew --prefix)/var/orbiter` and logs to
`$(brew --prefix)/var/log/orbiter.log`, and restarts if it stops with an
error. Update with `brew upgrade orbiter` - the agent doesn't update itself
when Homebrew installed it.

Your master key decrypts your backups and can't be recovered: save it
somewhere safe. With it, `orbiter recover --input <backup>.tar.gz.enc`
decrypts any backup on any machine.

## From bckupx-agent

The formula was `bckupx-agent` before the rename (0.1.46 and earlier).
`formula_renames.json` moves an install of it to `orbiter` on `brew update`;
trust the new name first, since Homebrew doesn't carry trust across a rename:

```
brew trust lekejosh/concentric      # or the name you tapped it under
brew update && brew upgrade orbiter
```

The upgrade moves `etc/bckupx/agent.env` to `etc/orbiter/orbiter.env` and
`var/bckupx` to `var/orbiter` (a link is left at the old path). Its caveats
then show how to swap the running `bckupx-agent` service for `orbiter`'s.

## Releases

`Formula/orbiter.rb` downloads the agent binaries from `get.concentric.sh`,
checked against each release's `manifest.json`. The agent's release workflow
runs `./update-formula.sh <version>` and pushes the result on every stable
release; to do it by hand:

```
./update-formula.sh 0.1.47
git commit -am "orbiter 0.1.47" && git push
```
