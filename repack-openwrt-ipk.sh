#!/usr/bin/env bash

set -euo pipefail

openwrt_release="${OPENWRT_RELEASE:-24.10.0}"
openwrt_arch="${OPENWRT_ARCH:-aarch64_cortex-a53}"
feed_dir="${OPENWRT_FEED_DIR:-packages}"
download_root="https://downloads.openwrt.org/releases/${openwrt_release}/packages/${openwrt_arch}/${feed_dir}"
packages_index_url="${download_root}/Packages.gz"
stub_script='#!/bin/sh
true
'

package_filename="$(curl -fsSL "$packages_index_url" | gzip -dc | python3 -c '
import sys

for block in sys.stdin.read().split("\n\n"):
	fields = {}
	for line in block.splitlines():
		if ": " not in line:
			continue
		key, value = line.split(": ", 1)
		fields[key] = value
	if fields.get("Package") == "tailscale" and "Filename" in fields:
		print(fields["Filename"])
		sys.exit(0)

sys.exit(1)
')"

if [[ -z "$package_filename" ]]; then
	echo "Could not resolve tailscale package from $packages_index_url" >&2
	exit 1
fi

package="$(basename "$package_filename")"
package_dir="${package%.ipk}"

rm -rf "$package" "$package_dir"
curl -fsSLo "$package" "${download_root}/${package}"
mkdir -p "$package_dir"
pushd "$package_dir" >/dev/null
tar -xzf "../$package"

mkdir data
pushd data >/dev/null
tar -xzf ../data.tar.gz
if [[ -f usr/sbin/tailscaled ]]; then
	printf '%s' "$stub_script" > usr/sbin/tailscaled
	chmod 0755 usr/sbin/tailscaled
fi
tar --numeric-owner --group=0 --owner=0 -czf ../data.tar.gz .
popd >/dev/null
size="$(du -sb data | awk '{ print $1 }')"
rm -rf data

mkdir control
pushd control >/dev/null
tar -xzf ../control.tar.gz
sed -i "s/^Installed-Size:.*/Installed-Size: ${size}/" control
tar --numeric-owner --group=0 --owner=0 -czf ../control.tar.gz .
popd >/dev/null
rm -rf control

tar --numeric-owner --group=0 --owner=0 -czf "../$package" debian-binary data.tar.gz control.tar.gz
popd >/dev/null

printf '%s\n' "$package"
