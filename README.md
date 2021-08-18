# alpine-proot 
A script that used to emulate alpine linux with proot. This script also works for **__[Termux](https://termux.org)__**.

## Installation
```sh
curl -Lo alpine-proot.sh git.io/alpine-proot.sh
chmod +x alpine-proot.sh 

# To launch alpine proot anytime, do:
./alpine-proot.sh
```

## Sound supports
Your system must have `pulseaudio` installed for this to work. At startup, The script automatically launch `pulseaudio` in non-system mode. 
The script itself also binds `/tmp` from your `$TMPDIR` to work. In alpine session, Ran this command:
```sh
export PULSE_SERVER=unix:$(echo /tmp/pulse-*/native)
```
And ran some program that plays audio output.

Keep in mind that **__not every program__** supports pulse as audio output like `firefox` that drop pulseaudio support a year ago.

## Community
- Discord Server: https://discord.gg/9S3ZCDR

## Sources
- PRoot: https://proot-me.github.io
- Alpine Linux: https://alpinelinux.org
