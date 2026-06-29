'use strict';
'require view';
'require rpc';
'require fs';
'require ui';

var callInfo = rpc.declare({
	object: 'onlineupdate',
	method: 'get_info',
	expect: { }
});

var callDownload = rpc.declare({
	object: 'onlineupdate',
	method: 'download',
	params: ['url']
});

var callProgress = rpc.declare({
	object: 'onlineupdate',
	method: 'progress'
});

var callUpgrade = rpc.declare({
	object: 'onlineupdate',
	method: 'upgrade',
	params: ['keep']
});

return view.extend({

	load: function() {
		return callInfo();
	},

	render: function(data) {

		var current = data.current_version || '-';
		var latest = data.latest_version || '-';
		var body = data.body || '';
		var fw = data.firmware || null;

		var status = E('div', { 'class': 'cbi-section' }, [

			E('h3', {}, _('Online Update')),

			E('div', {}, _('Current Version') + ': ' + current),
			E('div', {}, _('Latest Version') + ': ' + latest),

			E('hr'),

			E('pre', {
				style: 'white-space: pre-wrap; background:#111; color:#eee; padding:10px;'
			}, body),

			E('hr'),

			E('div', {}, fw ? [
				E('div', {}, _('Firmware') + ': ' + fw.name),
				E('button', {
					'class': 'btn cbi-button cbi-button-apply',
					'click': function() {
						return callDownload(fw.url);
					}
				}, _('Download'))
			] : _('No firmware found')),

			E('hr'),

			E('button', {
				'class': 'btn cbi-button cbi-button-apply',
				'click': function() {
					return callProgress().then(function(res) {
						ui.addNotification(null,
							E('pre', {}, JSON.stringify(res, null, 2)));
					});
				}
			}, _('Check Progress')),

			E('hr'),

			E('div', {}, [

				E('label', {}, [
					E('input', {
						type: 'checkbox',
						id: 'keepcfg'
					}),
					' ' + _('Keep Config')
				]),

				E('br'),

				E('button', {
					'class': 'btn cbi-button cbi-button-danger',
					'click': function() {
						var keep = document.getElementById('keepcfg').checked;
						return callUpgrade(keep);
					}
				}, _('Upgrade Now'))
			])
		]);

		return status;
	}
});
