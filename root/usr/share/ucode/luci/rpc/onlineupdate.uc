'use strict';

import { ubus } from 'ubus';
import { request } from 'http';
import { fs } from 'fs';
import { exec } from 'process';

const API =
	'https://api.github.com/repos/huajiaoshu520/X86/releases/latest';

const STATE_FILE = '/tmp/onlineupdate_state.json';
const FW_FILE = '/tmp/firmware.img.gz';

function load_state() {
	try {
		return JSON.parse(fs.readfile(STATE_FILE));
	} catch {
		return {
			file: FW_FILE,
			url: null,
			status: 'idle',
			progress: 0
		};
	}
}

function save_state(st) {
	fs.writefile(STATE_FILE, JSON.stringify(st));
}

function get_system_version() {
	let res = ubus.call('system', 'board', {});
	return res?.release?.revision || 'unknown';
}

function fetch_github_release() {
	let r = request(API, {
		method: 'GET',
		headers: {
			'User-Agent': 'luci-app-onlineupdate'
		}
	});

	if (!r || r.status != 200)
		return null;

	return JSON.parse(r.body);
}

function pick_asset(assets) {
	if (!assets)
		return null;

	let keys = [
		'generic-squashfs-combined-efi.img.gz',
		'combined-efi.img.gz',
		'efi.img.gz'
	];

	for (let k of keys) {
		for (let a of assets) {
			if (a.name && a.name.includes(k))
				return a;
		}
	}

	return assets[0];
}

/* =========================
   RPC: 信息
========================= */
export function get_info() {
	let rel = fetch_github_release();
	if (!rel)
		return { error: 'github_failed' };

	let asset = pick_asset(rel.assets);

	return {
		current_version: get_system_version(),
		latest_version: rel.tag_name,
		body: rel.body,
		firmware: asset ? {
			name: asset.name,
			url: asset.browser_download_url,
			size: asset.size
		} : null
	};
}

/* =========================
   RPC: 下载
========================= */
export function download(url) {
	let st = load_state();

	st.url = url;
	st.status = 'downloading';
	st.progress = 0;

	save_state(st);

	// 后台下载
	exec(['wget', '-O', FW_FILE, url]);

	return { status: 'started' };
}

/* =========================
   RPC: 进度
========================= */
export function progress() {
	let st = load_state();

	let f = fs.stat(st.file);
	if (!f)
		return { progress: 0, status: st.status };

	// 注意：这里只是“伪进度”，真实 OpenWrt 无法从 wget 拿实时进度
	st.progress = f.size;

	save_state(st);

	return {
		status: st.status,
		progress: st.progress,
		file: st.file
	};
}

/* =========================
   RPC: 升级
========================= */
export function upgrade(keep) {
	let st = load_state();

	let f = fs.stat(st.file);
	if (!f)
		return { error: 'firmware_not_found' };

	st.status = 'upgrading';
	save_state(st);

	let cmd = keep
		? ['sysupgrade', '-c', st.file]
		: ['sysupgrade', st.file];

	exec(cmd);

	return {
		status: 'upgrading',
		keep_config: keep
	};
}
