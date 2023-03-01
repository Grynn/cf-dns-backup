## Cloudflare DNS Backup

The script `cf-dns-backup.sh` will backup all dns records for all domains in the specified Cloudflare accounts. It creates one zone file per domain. Zone files are simple text files and are added to git for simple history tracking.

I recommend running this once a day via cron.

## Install

```
git clone ...
make install
```

or brew install ...

### Configuration

Create `accounts.txt` and add the Cloudflare api tokens (one per line). You can get the tokens from https://dash.cloudflare.com/profile/api-tokens

If running via cron it is nicer to read tokens from a file that is not in the repo. 
The script checks `~/.cf-dns-backup/accounts.txt` if accounts.txt is found in the same directory as the script.

Tokens only need `Zone:DNS:Read` permission. Making read-only tokens is a good idea. Include all zones that you want to backup. 

![](help/cf-create-token.png)

You could need multiple tokens if you have multiple Cloudflare accounts (as I do, personal, work, etc). One token per account.

zone files are stored in `zones/` and git is used to track changes. 

After running `cf-dns-backup.sh` for the first time, you could add an origin to the git repo and push to a remote you trust!

```shell
cd zones
git remote add origin <url>
git push -u origin main
```

If a remote is configured, `cf-dns-backup` will try pushing automatically (if changes are detected).

### Usage

Run via cron once a day or adhoc
If running via cron it is nicer to read tokens from a file that is not in the repo. 
The script checks `~/.cf-dns-backup/accounts.txt` if not accounts.txt is found in the same directory as the script.

```
/fullpath/to/cf-dns-backup.sh
```

Use git log, git show etc to examine history. Sync is one way only, so you can't push changes back to Cloudflare.

### Requirements

* gnu parallel
* gnu sed (install `coreutils` via homebrew)
* jq
* flarectl
* git (well, you probably have that already)

Get 'em all with 
```
brew install coreutils parallel jq git flarectl
```
