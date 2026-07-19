# homebrew-bckupx

Homebrew tap for the [bckupx](https://bckupx.com) agent binary.

## Install

```
brew install lekejosh/bckupx/bckupx-agent
```

This installs the `bckupx-agent` binary only - no background service is
started or managed (see the formula's `caveats` for why). For a full
managed install (systemd/launchd, auto-restart, starts on boot), use the
installer instead:

```
curl -fsSL https://agents.bckupx.com/install.sh | sudo bash
```

## One-time setup (not done yet)

This directory is ready to become the actual tap, but the GitHub repo
doesn't exist yet:

```
gh repo create Lekejosh/homebrew-bckupx --public --source=. --push
```

(run from this directory - `--source=.` uses the local git history/files
you already have here rather than starting empty).

## Publishing an update

After a new agent version has a real GitHub release (see
`../agent/.github/workflows/release.yml` and
`../agent/packaging/DISTRIBUTION_SETUP.md`):

```
./update-formula.sh 0.1.1
git commit -am "bckupx-agent 0.1.1"
git push
```

`update-formula.sh` downloads that release's four platform tarballs,
recomputes their sha256s, and bumps `Formula/bckupx-agent.rb`'s `version`
line - the placeholder `REPLACE_WITH_SHA256` values in that file until the
first run of this script are why `brew install` won't work until then.
