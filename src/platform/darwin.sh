# Copyright (C) 2012 - 2014 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
# This file is licensed under the GPLv2+. Please see COPYING for more information.

clip() {
	local sleep_argv0="password store sleep for user $(id -u)"
	pkill -f "^$sleep_argv0" 2>/dev/null && sleep 0.5
	local before="$(pbpaste | openssl base64)"
	echo -n "$1" | pbcopy
	(
		( exec -a "$sleep_argv0" sleep "$CLIP_TIME" )
		local now="$(pbpaste | openssl base64)"
		[[ $now != $(echo -n "$1" | openssl base64) ]] && before="$now"
		echo "$before" | openssl base64 -d | pbcopy
	) 2>/dev/null & disown
	echo "Copied $2 to clipboard. Will clear in 45 seconds."
}

cleanup_tmp() {
	[[ -d $SECURE_TMPDIR ]] || return
	umount "$SECURE_TMPDIR"
	diskutil quiet eject "$ramdisk_dev"
	rm -rf "$tmp_file" "$SECURE_TMPDIR" 2>/dev/null
	rmdir "$SECURE_TMPDIR"
}

tmpdir() {
	trap cleanup_tmp INT TERM EXIT
	SECURE_TMPDIR="$(mktemp -t "$template" -d)"
	ramdisk_dev="$(hdid -drivekey system-image=yes -nomount 'ram://32768' | cut -d ' ' -f 1)" # 32768 sectors = 16 mb
	[[ -z $ramdisk_dev ]] && exit 1
	newfs_hfs -M 700 "$ramdisk_dev" &>/dev/null || exit 1
	mount -t hfs -o noatime -o nobrowse "$ramdisk_dev" "$SECURE_TMPDIR" || exit 1
}

GETOPT="$(brew --prefix gnu-getopt 2>/dev/null || echo /usr/local)/bin/getopt"
SHRED="srm -f -z"
