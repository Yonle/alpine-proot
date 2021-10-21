[![Alpine Linux](https://alpinelinux.org/alpinelinux-logo.svg)](https://alpinelinux.org)
# alpine-proot 
A well quick standalone Alpine PRoot installer & launcher. Also works for every architectures, Linux distros, and even in **__[Termux](https://termux.org)__**.

alpine-proot support both [Plain PRoot](https://github.com/proot-me/proot) and [proot-rs (Rust)](https://github.com/proot-me/proot-rs). If you have both proot and proot-rs installed, but you want to use proot-rs instead to launch alpine-proot, simply set [`ALPINEPROOT_USE_PROOT_RS`](https://github.com/Yonle/alpine-proot/wiki/Environment-Variables#alpineproot_use_proot_rs) as `true`.

## Installation
```sh
curl -Lo alpine-proot.sh git.io/alpine-proot.sh
chmod +x alpine-proot.sh 

# To launch alpine-proot anytime, simply do:
./alpine-proot.sh
```
It's very recommended to use [this](https://github.com/termux/proot) proot fork since this fork has a lot of fix & feature implemented *(P.S. This proot fork also works on other than Termux)*

For more information about alpine-proot, please check the alpine-proot [wiki](https://github.com/Yonle/alpine-proot/wiki).
## Sound support
In order to make this works, **__PulseAudio__** should be installed at host system. At startup, the script automatically launch PulseAudio server in non-system mode if there is no pulse UNIX socket detected. However, in [alpine-proot](https://github.com/Yonle/alpine-proot), sound support is already ready-to-use at startup as long you have PulseAudio and `alsa-plugins-pulse` installed on the host system.

## Online alpine-proot
https://replit.com/@Yonle/PRoot (1 GB Storage per anonymous user)

## Community
- Discord Server: https://discord.gg/9S3ZCDR

## Sources
- PRoot: https://proot-me.github.io
- Alpine Linux: https://alpinelinux.org
