#!/usr/bin/env sh

# alpine-proot - A script that used to emulate alpine linux with proot
# https://github.com/Yonle/alpine-proot

if [ ! $HOME ]; then export HOME=/home; fi

if [ ! $PREFIX ] && [ -x /usr ]; then
  export PREFIX=/usr
fi

if [ ! $TMPDIR ]; then export TMPDIR=/tmp; fi

CONTAINER_PATH="$HOME/.container"
CONTAINER_DOWNLOAD_URL="https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/$(uname -m)/alpine-minirootfs-3.14.1-$(uname -m).tar.gz"

if [ ! -x $CONTAINER_PATH ]; then
  curl -L#o $HOME/cont.tar.gz $CONTAINER_DOWNLOAD_URL
  if [ $? != 0 ]; then exit 1; fi
  mkdir $CONTAINER_PATH && cd $CONTAINER_PATH
  tar -xzf $HOME/cont.tar.gz && rm $HOME/cont.tar.gz

  echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > $CONTAINER_PATH/etc/resolv.conf
fi

clear

if [ "$(uname -o)" = "Android" ]; then unset LD_PRELOAD; fi

# Detect pulseaudio with POSIX support
if pulseaudio=$(command -v pulseaudio); then
  $pulseaudio --start --exit-idle-time=-1
fi

if ! proot=$(command -v proot); then
  if [ "$(uname -o)" = "Android" ] && pkg=$(command -v pkg); then
    pkg install proot -y
    curl -L# https://raw.githubusercontent.com/Yonle/alpine-proot/master/main.sh | sh
    exit
  fi
  echo "PRoot must be installed in order to execute this script."
  echo "More information can go to https://proot-me.github.io"
  exit 1
fi

if [ -f $CONTAINER_PATH/etc/motd ] && [ ! -f $CONTAINER_PATH/root/.hushlogin ]; then
  cat $CONTAINER_PATH/etc/motd
else
  cat $CONTAINER_PATH/root/.hushlogin
fi

proot \
  --link2symlink \
  --kill-on-exit \
  --kernel-release=5.4.0 \
  -r $CONTAINER_PATH -0 \
  -w /root -b $TMPDIR:/tmp \
  -b /dev -b $CONTAINER_PATH/root:/dev/shm \
  -b /proc -b /sys /bin/su -l
