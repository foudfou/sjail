.POSIX:

all:

# We might want to package this at some point
install: check-root
	install -o root -g wheel src/sjail /usr/local/bin
	install -o root -g wheel -d /usr/local/share/sjail
	install -o root -g wheel -m 644 src/cmd.sh src/common.sh src/version.sh /usr/local/share/sjail
	install -o root -g wheel -m 644 src/sjail.conf.sample /usr/local/etc

deinstall: check-root
	rm /usr/local/bin/sjail
	rm -fr /usr/local/share/sjail

check-root:
	@if [ $$(id -u) -ne 0 ]; then \
echo "Error: you must be root to perform this action."; \
false; \
fi

ls-install:
	ls -l /usr/local/bin/sjail /usr/local/share/sjail/* /usr/local/etc/sjail.conf.sample

# SC3037 In POSIX sh, echo flags are undefined.
# SC3043 In POSIX sh, 'local' is undefined.
SHELLCHECK_OPTS = -e SC3037,SC3043

.PHONY: lint
lint:
	shellcheck $(SHELLCHECK_OPTS) src/sjail
	shellcheck $(SHELLCHECK_OPTS) -x src/sjail src/cmd.sh src/common.sh

.PHONY: test-unit
test-unit:
	prove t/*_test.sh

.PHONY: test-integration
test-integration:
	prove t/integration/*_test.sh

# Could also use `git-vsn -t v`
SJAIL_VERSION = $(shell git describe --tags)

.PHONY: package
package:
	@archive="sjail-$(SJAIL_VERSION).tar.xz"; \
sed -i -e 's/SJAIL_VERSION=.*/SJAIL_VERSION="'"$(SJAIL_VERSION)"'"/' src/version.sh; \
( git archive HEAD | xz > "$${archive}" ); \
printf "Created %s\n" "$${archive}"
