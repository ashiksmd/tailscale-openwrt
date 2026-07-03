# tailscale-openwrt

Automated Tailscale builds for OpenWrt 24.10 on arm64

On devices with 16 MB of flash or less, the stock Tailscale package and its dependencies can take up too much space.
Tailscale's build system provides a `multicall` target that lets `tailscale` and `tailscaled` share a single binary, which cuts the storage footprint significantly. To shrink it further, this project strips debug symbols and compresses the resulting binary with `upx`.

To preserve normal OpenWrt package behavior, this repository also republishes the OpenWrt `tailscale.ipk` with a stubbed `tailscaled` binary. That keeps the package metadata, init script integration, and `opkg` state intact while still letting the system run the smaller `tailscale.multicall` binary.

## How it works

- `upstream-version.txt` stores the upstream Tailscale tag to build.
- `.github/workflows/check-tailscale-release.yml` checks for the latest upstream Tailscale release and updates `upstream-version.txt` when it changes.
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