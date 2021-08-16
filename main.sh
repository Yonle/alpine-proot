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

  cp $PREFIX/etc/resolv.conf $CONTAINER_PATH/etc/resolv.conf
fi

clear

if [ "$(uname -o)" = "Android" ]; then unset LD_PRELOAD;fi

if [ -f $CONTAINER_PATH/etc/motd ] && [ ! -f $CONTAINER_PATH/root/.hushlogin ]; then
  cat $CONTAINER_PATH/etc/motd
else
  cat $CONTAINER_PATH/root/.hushlogin
fi

proot --link2symlink -r $CONTAINER_PATH -0 -w /root -b $TMPDIR -b /dev -b /proc -b /sys /usr/bin/env HOME=/root LANG=C.UTF-8 TERM=xterm-256color PATH=/bin:/sbin:/usr/bin:/usr/sbin /bin/su
