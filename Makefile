.PHONY: install

install:
	install -C ./cf-dns-backup.sh /usr/local/bin/cf-dns-backup

link:
	#like npm link
	ln -s "$PWD/cf-dns-backup.sh" /usr/local/bin/cf-dns-backup
