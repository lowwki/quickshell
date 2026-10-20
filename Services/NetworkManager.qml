pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


Singleton {
  id: root

  property var devices: []
  property var defaultAdapter: null
  property string ipAddress: "0.0.0.0"

  property bool connectedWifi: defaultAdapter != null && defaultAdapter.connected && defaultAdapter.isWifi
  property bool online: devices.some(d => d.connected)

  function pickDefault(list) {
	let wifi = null;
	let wired = null;
	for (let d of list) {
	  if (d.isWifi) {
		if (d.connected)
		  return d;
		wifi = wifi || d;
	  } else if (d.connected) {
		wired = wired || d;
	  }
	}
	return wired || wifi || list[0] || null;
  }

  function parseDevices(text) {
	let list = [];
	for (let line of text.split("\n")) {
	  if (line.trim() === "")
		continue;
	  const p = line.split("|");
	  if (p.length < 6)
		continue;
	  const isWifi = p[1] === "wifi";
	  const dbm = parseInt(p[5]);
	  let strength = 0;
	  if (!isNaN(dbm))
		strength = Math.max(0, Math.min(1, (dbm + 90) / 60));
	  list.push({
		"name": p[0],
		"isWifi": isWifi,
		"connected": p[2] === "up" && (isWifi ? p[4] !== "" : true),
		"ip": p[3],
		"ssid": p[4],
		"strength": strength
	  });
	}
	return list;
  }

  function getConnectedNetworks(networksArr) {
	return networksArr.filter(n => n.connected);
  }

  function getNetworkDetails(adapter) {
	if (!adapter) {
	  return {
		"adapterName": "",
		"adapterConnected": false,
		"adapterIsWifi": false,
		"networkName": "",
		"networkStrength": 0,
		"icon": "󰤭"
	  };
	}

	if (!adapter.isWifi) {
	  return {
		"adapterName": adapter.name,
		"adapterConnected": adapter.connected,
		"adapterIsWifi": false,
		"networkName": adapter.connected ? "Wired" : "No Network",
		"networkStrength": 1,
		"icon": adapter.connected ? "󰈀" : "󰤭",
		"saved": true,
		"ipAddress": root.ipAddress
	  };
	}

	if (!adapter.connected) {
	  return {
		"adapterName": adapter.name,
		"adapterConnected": false,
		"adapterIsWifi": true,
		"networkName": "No Network",
		"networkStrength": 0,
		"icon": "󰤭"
	  };
	}

	return {
	  "adapterName": adapter.name,
	  "adapterConnected": true,
	  "adapterIsWifi": true,
	  "networkName": adapter.ssid,
	  "networkStrength": adapter.strength,
	  "icon": getWifiIcon(adapter.strength),
	  "saved": true,
	  "ipAddress": root.ipAddress
	};
  }

  function getWifiIcon(strength) {
	let iconArr = ["󰤟", "󰤢", "󰤥", "󰤨"];
	let strengthIndex = Math.max(1, Math.ceil(strength * iconArr.length));
	return iconArr[strengthIndex - 1];
  }

  function getWifiText() {
	let info = getNetworkDetails(defaultAdapter);
	return info["adapterName"] + " - " + info["networkName"];
  }

  function isConnectedAndWifi() {
	return root.connectedWifi;
  }

  function isDeviceWifi(adapter) {
	return adapter != null && adapter.isWifi === true;
  }

  function refreshIpAddress() {
	refresh();
  }

  function refresh() {
	if (!poll.running)
	  poll.running = true;
  }

  Timer {
	interval: 3000
	running: true
	repeat: true
	triggeredOnStart: true
	onTriggered: root.refresh()
  }


  Process {
	id: poll

	command: ["sh", "-c", `
	  for d in /sys/class/net/*; do
		n=$(basename "$d")
		[ "$n" = lo ] && continue
		if [ -e "$d/wireless" ]; then t=wifi
		elif [ -e "$d/device" ]; then t=wired
		else continue; fi
		s=$(cat "$d/operstate" 2>/dev/null)
		ip4=$(ip -4 -o addr show dev "$n" scope global 2>/dev/null | awk '{sub("/.*", "", $4); print $4; exit}')
		ssid=""; sig=""
		if [ "$t" = wifi ] && [ "$s" = up ]; then
		  l=$(iw dev "$n" link 2>/dev/null)
		  ssid=$(printf '%s\n' "$l" | awk -F'SSID: ' '/SSID:/{print $2; exit}')
		  sig=$(printf '%s\n' "$l" | awk '/signal:/{print $2; exit}')
		fi
		echo "$n|$t|$s|$ip4|$ssid|$sig"
	  done
	`]
	running: false

	stdout: StdioCollector {
	  onStreamFinished: {
		const list = root.parseDevices(this.text);
		root.devices = list;
		root.defaultAdapter = root.pickDefault(list);
		root.ipAddress = (root.defaultAdapter && root.defaultAdapter.connected && root.defaultAdapter.ip !== "")
		  ? root.defaultAdapter.ip : "0.0.0.0";
	  }
	}
  }
}
