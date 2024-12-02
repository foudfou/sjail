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

# SC3037 In POSIX sh, echo flags are undefined.
# SC3043 In POSIX sh, 'local' is undefined.
SHELLCHECK_OPTS = -e SC3037,SC3043

.PHONY: lint
lint:
	shellcheck $(SHELLCHECK_OPTS) src/sjail
	shellcheck $(SHELLCHECK_OPTS) -x src/sjail src/cmd.sh src/common.sh

.PHONY: test
test:
	prove t/*_test.sh
