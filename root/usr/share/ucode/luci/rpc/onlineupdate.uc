'use strict';

import { ubus } from 'ubus';
import { request } from 'http';
import { fs } from 'fs';

const REPO_API =
	'https://api.github.com/repos/huajiaoshu520/X86/releases/latest';

function get_system_version() {
	let res = ubus.call('system', 'board', {});
	return res?.release?.revision || 'unknown';
}

function fetch_github_release() {
	let r = request(REPO_API, {
		method: 'GET',
		headers: {
			'User-Agent': 'luci-app-onlineupdate'
		}
	});

	if (!r || r.status != 200)
		return null;

	return JSON.parse(r.body);
}

function pick_firmware_asset(assets) {
	if (!assets)
		return null;

	let priority = [
		'generic-squashfs-combined-efi.img.gz',
		'combined-efi.img.gz',
		'efi.img.gz'
	];

	for (let p of priority) {
		for (let a of assets) {
			if (a.name && a.name.indexOf(p) >= 0)
				return a;
		}
	}

	// fallback
	return assets[0];
}

export function get_info() {
	let sysver = get_system_version();
	let rel = fetch_github_release();

	if (!rel)
		return { error: 'github_failed' };

	let asset = pick_firmware_asset(rel.assets);

	return {
		current_version: sysver,
		latest_version: rel.tag_name,
		body: rel.body,
		firmware: asset ? {
			name: asset.name,
			url: asset.browser_download_url,
			size: asset.size
		} : null
	};
}

export function check() {
	return get_info();
}
