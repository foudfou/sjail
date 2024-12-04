#!/bin/sh
# https://github.com/dnmfarrell/tap.sh
TAP_TEST_COUNT=0
TAP_FAIL_COUNT=0

tap_pass() {
	TAP_TEST_COUNT=$((TAP_TEST_COUNT + 1))
	echo "ok $TAP_TEST_COUNT $1"
}

tap_fail() {
	TAP_TEST_COUNT=$((TAP_TEST_COUNT + 1))
	TAP_FAIL_COUNT=$((TAP_FAIL_COUNT + 1))
	echo "not ok $TAP_TEST_COUNT $1"
}

tap_end() {
	num_tests="$1"
	[ -z "$num_tests" ] && num_tests="$TAP_TEST_COUNT"
	echo "1..$num_tests"
	[ "$num_tests" = "$TAP_TEST_COUNT" ] || exit 1
	exit $((TAP_FAIL_COUNT > 0)) # C semantics
}

tap_ok() {
	if [ "$1" -eq 0 ]; then
		tap_pass "$2"
	else
		tap_fail "$2"
	fi
}

tap_cmp() {
	if [ "$1" = "$2" ]; then
		tap_pass "$3"
	else
		tap_fail "$3 - expected '$2' but got '$1'"
	fi
}

# MIT License
#
# Copyright (c) 2021 David Farrell
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
