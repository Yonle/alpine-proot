# alpine-proot 
A Well quick standalone alpine proot installer & launcher. Also works for every arch, linux distros, and even in **__[Termux](https://termux.org)__**.

## Installation
```sh
curl -Lo alpine-proot.sh git.io/alpine-proot.sh
chmod +x alpine-proot.sh 

# To launch alpine proot anytime, do:
./alpine-proot.sh
```

For more information about alpine-proot, Please check alpine-proot [wiki](https://github.com/Yonle/alpine-proot/wiki).
## Sound supports
In order to make this works, **__PulseAudio__** should be installed at host system. At startup, The script automatically launch pulseaudio server in non-system mode if there's no UNIX socket detected at `$PREFIX/var/run/pulse/native`. However, In this [alpine-proot](https://github.com/Yonle/alpine-proot), Sound support is already ready-to-use at startup as long you have pulseaudio installed in host.

Keep in mind that **__not every program__** supports pulse as audio output like `firefox` that drop pulseaudio support a year ago.

## Online alpine-proot
https://replit.com/@Yonle/PRoot (1 GB Storage per anonymous user)

## Community
- Discord Server: https://discord.gg/9S3ZCDR

## Sources
- PRoot: https://proot-me.github.io
- Alpine Linux: https://alpinelinux.org
