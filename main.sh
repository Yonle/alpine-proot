#!/usr/bin/env bash

# alpine-proot - A script that used to emulate alpine linux with proot
# https://github.com/Yonle/alpine-proot

if [ ! $HOME ]; then export HOME=/home; fi

if [ ! $PREFIX ] && [ -x /usr ]; then
  export PREFIX=/usr
fi

if [ ! $TMPDIR ]; then export TMPDIR=/tmp; fi

if [ ! $CONTAINER_PATH ]; then export CONTAINER_PATH="$HOME/.container"; fi
if [ ! $CONTAINER_DOWNLOAD_URL ]; then export CONTAINER_DOWNLOAD_URL="https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/$(uname -m)/alpine-minirootfs-3.14.1-$(uname -m).tar.gz"; fi

if [ ! -x $CONTAINER_PATH ]; then
  curl -L#o $HOME/cont.tar.gz $CONTAINER_DOWNLOAD_URL
  if [ $? != 0 ]; then exit 1; fi
  mkdir $CONTAINER_PATH && cd $CONTAINER_PATH
  tar -xzf $HOME/cont.tar.gz && rm $HOME/cont.tar.gz

  echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > $CONTAINER_PATH/etc/resolv.conf
fi

clear

if [ "$(uname -o)" = "Android" ]; then unset LD_PRELOAD; fi

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

COMMANDS="proot"
COMMANDS+=" --link2symlink"
COMMANDS+=" --kill-on-exit"
COMMANDS+=" --kernel-release=5.4.0"
COMMANDS+=" -r $CONTAINER_PATH -0"
COMMANDS+=" -w /root -b /dev -b /proc -b /sys"
COMMANDS+=" -b $CONTAINER_PATH/root:/dev/shm"

# Detect whenever Pulseaudio is installed with POSIX support
if pulseaudio=$(command -v pulseaudio) && [ ! -f $PREFIX/var/run/pulse/native ]; then
  if [ ! $ALPINEPROOT_NO_PULSE ]; then
    $pulseaudio --start --exit-idle-time=-1
    if [ $? = 0 ]; then COMMANDS+=" -b $(echo $TMPDIR/pulse-*/native):/var/run/pulse/native"; fi
    if [ -f $CONTAINER_PATH/etc/pulse/client.conf ]; then sed -i "s/default-server =/default-server = unix:\/\/\/var\/run\/pulse\/native/g" $CONTAINER_PATH/etc/pulse/client.conf; fi
  fi
else
  if [ ! $ALPINEPROOT_NO_PULSE ]; then
    if [ -f $PREFIX/var/run/pulse/native ]; then COMMANDS+=" -b $PREFIX/var/run/pulse/native:/var/run/pulse/native"; fi;
    if [ -f $CONTAINER_PATH/etc/pulse/client.conf ]; then sed -i "s/default-server =/default-server = unix:\/\/\/var\/run\/pulse\/native/g" $CONTAINER_PATH/etc/pulse/client.conf; fi
  fi
fi

if [ $@ ]; then
  $COMMANDS /bin/su -c $@
else
  if [ -f $CONTAINER_PATH/etc/motd ] && [ ! -f $CONTAINER_PATH/root/.hushlogin ]; then
    cat $CONTAINER_PATH/etc/motd
  else
    if [ -f $CONTAINER_PATH/root/.hushlogin ]; then cat $CONTAINER_PATH/root/.hushlogin; fi
  fi
  $COMMANDS /bin/su -l
fi
