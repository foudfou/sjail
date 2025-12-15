.POSIX:

all:

# We might want to package this at some point
install: check-root
	install -o root -g wheel src/sjail /usr/local/sbin
	install -o root -g wheel -d /usr/local/share/sjail
	install -o root -g wheel -m 644 src/recipe.sh src/common.sh src/version.sh /usr/local/share/sjail
	install -o root -g wheel -m 644 src/sjail.conf.sample /usr/local/etc

deinstall: check-root
	rm /usr/local/sbin/sjail
	rm -fr /usr/local/share/sjail

check-root:
	@if [ $$(id -u) -ne 0 ]; then \
echo "Error: you must be root to perform this action."; \
false; \
fi

ls-install:
	ls -l /usr/local/sbin/sjail /usr/local/share/sjail/* /usr/local/etc/sjail.conf.sample

# SC3037 In POSIX sh, echo flags are undefined.
# SC3043 In POSIX sh, 'local' is undefined.
SHELLCHECK_OPTS = -e SC3037,SC3043

.PHONY: lint
lint:
	shellcheck $(SHELLCHECK_OPTS) src/sjail
	shellcheck $(SHELLCHECK_OPTS) -x src/sjail src/recipe.sh src/common.sh

.PHONY: test-unit
test-unit:
	prove t/*_test.sh

.PHONY: test-integration
test-integration:
	prove t/integration/*_test.sh

# Could also use `git-vsn -t v`. Note the POSIX makefile variable assignment
# from a shell output is `!=`; but git might not be needed in all
# cases/targets, so we only use it where needed.
.PHONY: package
package:
	@version=$$(git describe --tags | sed -e 's/^v//; s/-[[:digit:]]\+-g/+/'); \
archive="sjail-$${version}.tar.xz"; \
sed -i -e 's/SJAIL_VERSION=.*/SJAIL_VERSION="'"$${version}"'"/' src/version.sh; \
( git archive --prefix sjail/ HEAD | xz > "$${archive}" ); \
printf "Created %s\n" "$${archive}"

.PHONY: clean
clean:
	rm sjail-*.tar.xz
