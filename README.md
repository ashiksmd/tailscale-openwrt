# tailscale-openwrt

Automated Tailscale builds for OpenWrt 24.10.

This repository tracks the latest upstream Tailscale release, builds a compressed `tailscale.multicall` binary for `linux/arm64`, and publishes release assets containing:

- A stub OpenWrt `tailscale` IPK based on the latest package available in the OpenWrt 24.10 feed
- A `tailscale.multicall` binary built from the upstream Tailscale tag recorded in `upstream-version.txt`

## How it works

- `upstream-version.txt` stores the upstream Tailscale tag to build.
- `.github/workflows/update-upstream-version.yml` checks for the latest upstream Tailscale release and updates `upstream-version.txt` when it changes.
- `.github/workflows/new-release.yml` runs when `upstream-version.txt` changes, rebuilds the release artifacts, and creates a GitHub release tagged with that version.
- `repack-openwrt-ipk.sh` downloads the latest `tailscale` IPK from the OpenWrt package feed and replaces the bundled `tailscaled` binary with a stub.

## Install

Download the release assets for your target version and copy both files to the router.

Install the stub package:

```sh
opkg install tailscale_*.ipk
```

Place the multicall binary in `/usr/sbin/`:

```sh
install -m 0755 tailscale.multicall /usr/sbin/tailscale.multicall
```

Point both commands at the multicall binary:

```sh
ln -sf /usr/sbin/tailscale.multicall /usr/sbin/tailscale
ln -sf /usr/sbin/tailscale.multicall /usr/sbin/tailscaled
```