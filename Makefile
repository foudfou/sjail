all:

# We might want to package this at some point
install: check-root
	install -o root -g wheel src/sjail /usr/local/bin
	install -o root -g wheel -d /usr/local/share/sjail
	install -o root -g wheel -m 644 src/cmd.sh src/common.sh /usr/local/share/sjail
	install -o root -g wheel -m 644 src/sjail.conf.sample /usr/local/etc

deinstall: check-root
	rm /usr/local/bin/sjail
	rm -fr /usr/local/share/sjail

check-root:
.if $(.MAKE.UID) != 0
	@echo "Error: you must be root to perform this action."
	@false
.endif

ls-install:
	ls -l /usr/local/bin/sjail /usr/local/share/sjail/* /usr/local/etc/sjail.conf.sample

test:
	test.sh t/*
