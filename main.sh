#!/usr/bin/env bash

# alpine-proot - A quick standalone Alpine Linux proot installer & launcher
# https://github.com/Yonle/alpine-proot

[ $(uname -s) != "Linux" ] && [ ! "$ALPINEPROOT_FORCE" ] && exec echo "Expected Linux kernel, But got unsupported kernel ($(uname -s))."

[ -x "${ALPINEPROOT_RC_PATH:-~/.alpineprootrc}" ] && source "${ALPINEPROOT_RC_PATH:-~/.alpineprootrc}"

! [ -z "$ALPINEPROOT_FORCE" ] && echo "Warning: I'm sure you know what are you doing."

# Do not run if user run this script as root
[ "$(id -u)" = "0" ] && [ -z "$ALPINEPROOT_FORCE" ] && echo "Running alpine-proot as root is dangerous and can harm one of your system component. Because of that, I'm aborting now. You may set ALPINEPROOT_FORCE variable as 1 if you want to continue." && exit 6

[ -z "$HOME" ] && export HOME=/home
[ -z "$PREFIX" ] && [ -x /usr ] && [ -d /usr ] && export PREFIX=/usr
[ -z "$TMPDIR" ] && export TMPDIR=/tmp
[ -z "$CONTAINER_PATH" ] && export CONTAINER_PATH="$HOME/.alpinelinux_container"
[ -z "$ALPINEPROOT_LAUNCHPAD" ] && export ALPINEPROOT_LAUNCHPAD="$HOME/.alpineproot_launchpad"

__start() {
	unset LD_PRELOAD

	COMMANDS=`cat "$ALPINEPROOT_LAUNCHPAD"`

	if [ "$#" = 0 ]; then
		eval "exec $COMMANDS /bin/su -l"
	else
		eval "exec $COMMANDS /bin/su -l -c \"$@\""
	fi
}

[ -f "$ALPINEPROOT_LAUNCHPAD" ] && __start $@

export CONTAINER_DOWNLOAD_URL=""

__install() {
	TD="$TMPDIR/alpine-proot-tmpdir"

	mkdir -p "$TD" || exit $?

	[ -z "$CONTAINER_DOWNLOAD_URL" ] && __get_container_url

	FILENAME=`basename "$CONTAINER_DOWNLOAD_URL"`

	# Download
	for i in ".sha256" "" ; do
		(
			F="${TD}/${FILENAME}${i}"
			U="${CONTAINER_DOWNLOAD_URL}${i}"
			! [ -f "$F" ] && \
				curl -fSL`([ "$i" == "" ] && echo \#) || echo s`o "$F" "$U" || \
				(echo -e "\nFailed to fetch $U."; rm "$F"; exit 7)
		) &
	done

	# As they are running in parallel, We will wait till all of them finishes.
	wait

	realsha256=`cat "${TD}/${FILENAME}.sha256" | awk '{ print $1 }'`
	thissha256=`sha256sum "${TD}/${FILENAME}" | awk '{ print $1 }'`

	if [ "$realsha256" != "$thissha256" ]; then
		echo "Unmatched SHA256 hash."
		echo ""
		echo "Expected hash : $realsha256"
		echo "Downloaded    : $thissha256"
		echo ""
		echo "Check your network connection and try again later."

		rm "${TD}/${FILENAME}"
		exit 1
	fi

	[ ! -d "$CONTAINER_PATH" ] && mkdir -p "$CONTAINER_PATH"

	# Use proot to prevent hard link extraction error
	proot --link2symlink tar -xzf "${TD}/${FILENAME}" -C "$CONTAINER_PATH"

	__prepare
}

__get_container_url() {
	CURRENT_VERSION=`(curl -fsSL https://alpinelinux.org/downloads/ | grep -oP '(?<=<strong>)[^<]+(?=</strong>)') || exit $?`

	CURRENT_VERSION_ID=`echo "$CURRENT_VERSION" | grep -oE '^[0-9]+\.[0-9]+'`

	echo "The following Alpine Linux version will be installed:"
	echo ""
	echo "Current Version: ${CURRENT_VERSION}"
	echo "Version ID: ${CURRENT_VERSION_ID}"
	echo ""

	CONTAINER_DOWNLOAD_URL="https://dl-cdn.alpinelinux.org/alpine/v${CURRENT_VERSION_ID}/releases/$(uname -m)/alpine-minirootfs-${CURRENT_VERSION}-$(uname -m).tar.gz"
}

__prepare() {
	echo -ne "nameserver 8.8.8.8\nnameserver 8.8.4.4" > "$CONTAINER_PATH/etc/resolv.conf"

	for i in dev/.shm proc; do
		rm -rf "$CONTAINER_PATH/$i"
		mkdir -p "$CONTAINER_PATH/$i"
	done

	# Proceed make fake /proc/version
	echo -n "Linux version ${ALPINEPROOT_KERNEL_RELEASE:-6.0.0+} (root@localhost) #1 SMP Fri Jul 23 12:00:00 PDT 2021" > "$CONTAINER_PATH/proc/.version"

	# Proceed make fake /proc/stat
	[ ! -r /proc/stat ] && cat <<-EOM > "$CONTAINER_PATH/proc/.stat"
cpu  5742 0 3915 205916 1204 0 339 82 0 0
cpu0 1428 0 904 51706 126 0 108 21 0 0
cpu1 1455 0 846 51772 99 0 87 20 0 0
cpu2 1235 0 864 52026 102 0 65 19 0 0
cpu3 1622 0 1300 50410 876 0 77 21 0 0
intr 1181516 235 9 0 0 1703 0 241 0 0 0 542 0 3 0 0 0 0 0 0 0 0 0 0 0 0 5 0 0 1 26315 0 641 571 691 623 674 581 961 599 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 199763
btime 1629638266
processes 1
procs_running 1
procs_blocked 0
softirq 562902 0 237872 366 6862 26279 0 9 122617 0 168897
EOM

	# Proceed make fake /proc/uptime
	[ ! -r /proc/uptime ] && echo -n "1302.49 5018.43" > "$CONTAINER_PATH/proc/.uptime"

	# Proceed make fake /proc/loadavg
	[ ! -r /proc/loadavg ] && echo -n "0.54 0.22 0.13 1/461 650" > "$CONTAINER_PATH/proc/.loadavg"

	# Proceed make fake /proc/vmstat
	[ ! -r /proc/vmstat ] && cat <<-EOM > "$CONTAINER_PATH/proc/.vmstat"
nr_free_pages 3621122
nr_zone_inactive_anon 13457
nr_zone_active_anon 93331
nr_zone_inactive_file 180805
nr_zone_active_file 116706
nr_zone_unevictable 0
nr_zone_write_pending 273
nr_mlock 0
nr_page_table_pages 1560
nr_kernel_stack 7424
nr_bounce 0
nr_zspages 1385
nr_free_cma 0
numa_hit 9934918
numa_miss 0
numa_foreign 0
numa_interleave 2111
numa_local 9934918
numa_other 0
nr_inactive_anon 13457
nr_active_anon 93331
nr_inactive_file 180805
nr_active_file 116706
nr_unevictable 0
nr_slab_reclaimable 37930
nr_slab_unreclaimable 15580
nr_isolated_anon 0
nr_isolated_file 0
workingset_nodes 73
workingset_refault 1285
workingset_activate 460
workingset_restore 423
workingset_nodereclaim 0
nr_anon_pages 112449
nr_mapped 87383
nr_file_pages 291852
nr_dirty 273
nr_writeback 0
nr_writeback_temp 0
nr_shmem 286
nr_shmem_hugepages 0
nr_shmem_pmdmapped 0
nr_file_hugepages 0
nr_file_pmdmapped 0
nr_anon_transparent_hugepages 1
nr_unstable 0
nr_vmscan_write 4383
nr_vmscan_immediate_reclaim 0
nr_dirtied 45538
nr_written 48611
nr_kernel_misc_reclaimable 0
nr_dirty_threshold 775081
nr_dirty_background_threshold 387067
pgpgin 1116233
pgpgout 217429
pswpin 1
pswpout 4383
pgalloc_dma 0
pgalloc_dma32 0
pgalloc_normal 10007308
pgalloc_movable 0
allocstall_dma 0
allocstall_dma32 0
allocstall_normal 0
allocstall_movable 0
pgskip_dma 0
pgskip_dma32 0
pgskip_normal 0
pgskip_movable 0
pgfree 13629652
pgactivate 92685
pgdeactivate 23439
pglazyfree 8319
pgfault 10640127
pgmajfault 6033
pglazyfreed 0
pgrefill 25344
pgsteal_kswapd 0
pgsteal_direct 0
pgscan_kswapd 0
pgscan_direct 0
pgscan_direct_throttle 0
zone_reclaim_failed 0
pginodesteal 819
slabs_scanned 44091
kswapd_inodesteal 0
kswapd_low_wmark_hit_quickly 0
kswapd_high_wmark_hit_quickly 0
pageoutrun 0
pgrotated 3
drop_pagecache 0
drop_slab 0
oom_kill 0
pgmigrate_success 0
pgmigrate_fail 0
compact_migrate_scanned 0
compact_free_scanned 0
compact_isolated 0
compact_stall 0
compact_fail 0
compact_success 0
compact_daemon_wake 0
compact_daemon_migrate_scanned 0
compact_daemon_free_scanned 0
htlb_buddy_alloc_success 0
htlb_buddy_alloc_fail 0
unevictable_pgs_culled 0
unevictable_pgs_scanned 0
unevictable_pgs_rescued 0
unevictable_pgs_mlocked 0
unevictable_pgs_munlocked 0
unevictable_pgs_cleared 0
unevictable_pgs_stranded 0
thp_fault_alloc 0
thp_fault_fallback 0
thp_collapse_alloc 1
thp_collapse_alloc_failed 0
thp_file_alloc 0
thp_file_mapped 0
thp_split_page 0
thp_split_page_failed 0
thp_deferred_split_page 0
thp_split_pmd 0
thp_split_pud 0
thp_zero_page_alloc 0
thp_zero_page_alloc_failed 0
thp_swpout 0
thp_swpout_fallback 0
balloon_inflate 0
balloon_deflate 0
balloon_migrate 0
swap_ra 0
swap_ra_hit 0
EOM

	COMMANDS=proot
	COMMANDS+=" --link2symlink"
	COMMANDS+=" --kill-on-exit"
	COMMANDS+=" --kernel-release=\"${ALPINEPROOT_KERNEL_RELEASE:-5.18}\""
	COMMANDS+=" -b /dev -b /proc -b /sys"
	COMMANDS+=" -b /proc/self/fd:/dev/fd"
	COMMANDS+=" -b /proc/self/fd/0:/dev/stdin"
	COMMANDS+=" -b /proc/self/fd/1:/dev/stdout"
	COMMANDS+=" -b /proc/self/fd/2:/dev/stderr"
	for f in stat version loadavg vmstat uptime; do
		[ -f "$CONTAINER_PATH/proc/.$f" ] && COMMANDS+=" -b \"$CONTAINER_PATH/proc/.$f:/proc/$f\""
	done
	COMMANDS+=" -r \"$CONTAINER_PATH\" -0 -w /root"
	COMMANDS+=" -b \"$CONTAINER_PATH/dev/.shm:/dev/shm\""

	[ -n "$ALPINEPROOT_PROOT_OPTIONS" ] && COMMANDS+=" $ALPINEPROOT_PROOT_OPTIONS"

	# Detect whenever ALPINEPROOT_BIND_TMPDIR is available or no.
	[ -n "$ALPINEPROOT_BIND_TMPDIR" ] && COMMANDS+=" -b $TMPDIR:/tmp"

	echo -n "$COMMANDS" > "$ALPINEPROOT_LAUNCHPAD"
}

! [ -x "$CONTAINER_PATH/bin/busybox" ] && __install
! [ -f "$ALPINEPROOT_LAUNCHPAD" ] && __prepare
__start $@
