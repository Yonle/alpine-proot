#!/usr/bin/env bash

# alpine-proot - A well quick standalone alpine proot installer & launcher.
# https://github.com/Yonle/alpine-proot

if [ "$ALPINEPROOT_FORCE" ]; then
  echo "Warning: I'm sure you know what are you doing."
fi

# Do not run if user run this script as root
if [ $(id -u) = 0 ] && [ ! "$ALPINEPROOT_FORCE" ]; then
  echo "Running alpine-proot as root is dangerous and can harm one of your system component. Because of that, I'm aborting now. You may set ALPINEPROOT_FORCE variable as 1 if you want to continue."
  exit 6
fi

if [ ! $HOME ]; then
  export HOME=/home
fi

if [ ! $PREFIX ] && [ -x /usr ]; then
  if [ -d /usr ]; then
    export PREFIX=/usr
  fi
fi

if [ ! $TMPDIR ]; then
  export TMPDIR=/tmp
fi

if [ ! $CONTAINER_PATH ]; then
  export CONTAINER_PATH="$HOME/.container"
fi

if [ ! $CONTAINER_DOWNLOAD_URL ]; then
  export CONTAINER_DOWNLOAD_URL="https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/$(uname -m)/alpine-minirootfs-3.14.1-$(uname -m).tar.gz"
fi

alpineproot() {
  # Install / Reinstall if container directory is unavailable or empty.
  if [ ! -d $CONTAINER_PATH ] || [ -z "$(ls -A $CONTAINER_PATH)" ] || [ ! -x $CONTAINER_PATH/bin/su ]; then
    # Download rootfs if there's no rootfs download cache.
    if [ ! -f $HOME/.cached_rootfs.tar.gz ]; then
      if [ ! -x $(command -v curl) ]; then
        if [ "$(uname -o)" = "Android" ] && pkg=$(command -v pkg); then
          pkg install curl -y && alpineproot $@
          exit 0
        fi
        echo "libcurl is required in order to download rootfs manually"
        echo "More information can go to https://curl.se/libcurl"
        exit 6
      fi
      curl -L#o $HOME/.cached_rootfs.tar.gz $CONTAINER_DOWNLOAD_URL
      if [ $? != 0 ]; then exit 1; fi
    fi

    # Wipe and extract rootfs
    rm -rf $CONTAINER_PATH
    mkdir -p $CONTAINER_PATH
    tar -xzf $HOME/.cached_rootfs.tar.gz -C $CONTAINER_PATH

    # If extraction fail, Delete cached rootfs and try again
    if [ $? != 0 ]; then
      rm -f $HOME/.cached_rootfs.tar.gz && alpineproot $@
      exit 0
    fi

    echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > $CONTAINER_PATH/etc/resolv.conf
  fi

  if [ "$(uname -o)" = "Android" ]; then unset LD_PRELOAD; fi

  if ! proot=$(command -v proot); then
    if [ "$(uname -o)" = "Android" ] && pkg=$(command -v pkg); then
      pkg install proot -y && alpineproot $@
      exit 0
    fi
    echo "PRoot is required in order to execute this script."
    echo "More information can go to https://proot-me.github.io"
    exit 6
  fi

  COMMANDS="proot"
  COMMANDS+=" --link2symlink"
  COMMANDS+=" --kill-on-exit"
  COMMANDS+=" --kernel-release=5.4.0"
  COMMANDS+=" -b /dev -b /proc -b /sys"
  COMMANDS+=" -r $CONTAINER_PATH -0 -w /root"
  COMMANDS+=" -b $CONTAINER_PATH/root:/dev/shm"

  # Detect whenever Pulseaudio is installed with POSIX support
  if pulseaudio=$(command -v pulseaudio) && [ ! -S $PREFIX/var/run/pulse/native ]; then
    if [ ! $ALPINEPROOT_NO_PULSE ]; then
      $pulseaudio --start --exit-idle-time=-1
      if [ $? = 0 ] && [ -S "$(echo $TMPDIR/pulse-*/native)" ]; then
        COMMANDS+=" -b $(echo $TMPDIR/pulse-*/native):/var/run/pulse/native"
      fi
    fi
  else
    if [ ! $ALPINEPROOT_NO_PULSE ]; then
      if [ -S $PREFIX/var/run/pulse/native ]; then
        COMMANDS+=" -b $PREFIX/var/run/pulse/native:/var/run/pulse/native"
      fi
    fi
  fi

  if [ "$ALPINEPROOT_PROOT_OPTIONS" ]; then
    COMMANDS+=" $ALPINEPROOT_PROOT_OPTIONS"
  fi

  # Detect whenever ALPINEPROOT_BIND_TMPDIR is available or no.
  if [ $ALPINEPROOT_BIND_TMPDIR ]; then
    COMMANDS+=" -b $TMPDIR:/tmp"
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
}

alpineproot $@
