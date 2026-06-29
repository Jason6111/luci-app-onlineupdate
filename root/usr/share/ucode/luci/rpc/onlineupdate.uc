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
let download_state = {
	file: "/tmp/firmware.img.gz",
	url: null,
	progress: 0,
	status: "idle",
	pid: null
};
function download_firmware(url) {
	if (!url)
		return { error: "no_url" };

	download_state.url = url;
	download_state.status = "downloading";
	download_state.progress = 0;

	// 使用 wget（OpenWrt 标准工具）
	let cmd = [
		"wget",
		"-O",
		download_state.file,
		url
	];

	let pid = ubus.call("luci", "exec", {
		command: cmd
	});

	download_state.pid = pid;

	return {
		status: "started",
		file: download_state.file
	};
}
function get_progress() {
	try {
		let st = fs.stat(download_state.file);

		if (!st)
			return { progress: 0 };

		let size = st.size;

		// GitHub asset size 在 get_info 已返回
		let rel = fetch_github_release();
		let asset = pick_firmware_asset(rel.assets);

		let total = asset?.size || 1;

		let percent = Math.floor((size / total) * 100);

		if (percent >= 100)
			download_state.status = "done";

		return {
			progress: percent,
			downloaded: size,
			total: total,
			status: download_state.status
		};
	}
	catch (e) {
		return { progress: 0, error: e };
	}
}
export function download(url) {
	return download_firmware(url);
}

export function progress() {
	return get_progress();
}
function do_sysupgrade(keep) {
	let file = download_state.file;

	// 1. 检查文件是否存在
	let st = fs.stat(file);
	if (!st)
		return { error: "firmware_not_found" };

	// 2. 构造命令
	let cmd = keep
		? ["/sbin/sysupgrade", "-c", file]
		: ["/sbin/sysupgrade", file];

	// 3. 标记状态
	download_state.status = "upgrading";

	// 4. 执行 sysupgrade（OpenWrt 标准方式）
	let r = ubus.call("luci", "exec", {
		command: cmd
	});

	return {
		status: "started",
		keep_config: keep
	};
}
function prepare_upgrade() {
	if (!download_state.file)
		return { error: "no_firmware" };

	let st = fs.stat(download_state.file);
	if (!st || st.size < 1024 * 1024)
		return { error: "file_too_small" };

	// 确保下载完成
	if (download_state.status != "done")
		return { error: "download_not_finished" };

	return { ok: true };
}
export function upgrade(keep) {
	let check = prepare_upgrade();

	if (!check.ok)
		return check;

	return do_sysupgrade(keep);
}
