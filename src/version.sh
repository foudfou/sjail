# To bump the version:
# 1. change semver here
# 2. commit changes
# 3. git tag "v${SJAIL_VERSION}"
#
# `make package` will otherwise auto-update the version (to be committed afterwards).
#
# git-post-commit
# git diff --cached --name-status | grep -q -E 'M src/version.sh'
# if yes then git tag "v${SJAIL_VERSION}"
SJAIL_VERSION="0.3.1"
