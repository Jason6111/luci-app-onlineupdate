'use strict';

'require view';
'require rpc';
'require ui';

var callInfo = rpc.declare({
	object: 'onlineupdate',
	method: 'get_info'
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

function poll_progress() {
	return callProgress().then(function(res) {

		ui.addNotification(null,
			E('pre', {}, JSON.stringify(res, null, 2))
		);

		if (res && res.status !== 'upgrading' && res.progress < 100) {
			setTimeout(poll_progress, 2000);
		}
	});
}

return view.extend({

	load: function() {
		return callInfo();
	},

	render: function(data) {

		var fw = data.firmware;

		return E('div', { 'class': 'cbi-section' }, [

			E('h2', {}, _('Online Update')),

			E('div', {}, _('Current Version') + ': ' + data.current_version),
			E('div', {}, _('Latest Version') + ': ' + data.latest_version),

			E('hr'),

			E('pre', {
				style: 'white-space: pre-wrap; background:#111; color:#eee; padding:10px;'
			}, data.body || ''),

			E('hr'),

			fw ? E('div', {}, [

				E('div', {}, _('Firmware') + ': ' + fw.name),

				E('button', {
					'class': 'btn cbi-button cbi-button-apply',
					'click': function() {
						return callDownload(fw.url).then(poll_progress);
					}
				}, _('Download'))

			]) : E('div', {}, _('No firmware found')),

			E('hr'),

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

					if (!confirm(_('System will reboot after upgrade. Continue?')))
						return;

					return callUpgrade(keep);
				}
			}, _('Upgrade Now'))
		]);
	}
});
