pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
  id: root

  property bool connectedWifi: root.defaultAdapter != null && root.defaultAdapter.connected
							   && root.defaultAdapter.type == DeviceType.Wifi
  // True when any Wi-Fi or wired device is connected; the bar icon is shown only then
  property bool online: {
	for (let device of Networking.devices.values) {
	  if (device.connected && (device.type == DeviceType.Wifi || device.type == DeviceType.Wired))
		return true;
	}
	return false;
  }

  // Prefer a connected Wi-Fi device, then a connected wired one, then any Wi-Fi, then the first device
  property NetworkDevice defaultAdapter: {
	const devices = Networking.devices.values;
	let wifi = null;
	let wired = null;
	for (let device of devices) {
	  if (device.type == DeviceType.Wifi) {
		if (device.connected)
		  return device;
		wifi = wifi || device;
	  } else if (device.type == DeviceType.Wired && device.connected) {
		wired = wired || device;
	  }
	}
	return wired || wifi || devices[0] || null;
  }
  property string ipAddress: "0.0.0.0"
  // Computed once here; the bar widgets all read this instead of calling getNetworkDetails()
  readonly property var details: getNetworkDetails(defaultAdapter)

  function getConnectedNetworks(networksArr) {
	let connectedNetworks = [];

	for (let network of networksArr) {
	  if (network.state == ConnectionState.Connected) {
		connectedNetworks.push(network);
	  }
	}
	return connectedNetworks;
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

	// Wired devices have no Wi-Fi network list
	if (!isDeviceWifi(adapter)) {
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

	let networksArr = adapter.networks.values;
	let connectedNetworks = getConnectedNetworks(networksArr);

	let primaryNetwork = connectedNetworks[0];
	if (!primaryNetwork) {
	  return {
		"adapterName": adapter.name,
		"adapterConnected": adapter.connected,
		"adapterIsWifi": true,
		"networkName": "No Network",
		"networkStrength": 0,
		"icon": "󰤭"
	  };
	}

	let networkName = primaryNetwork.name;
	let networkStrength = primaryNetwork.signalStrength;

	let networkIcon = getWifiIcon(networkStrength);

	let outputDict = {
	  "adapterName": adapter.name,
	  "adapterConnected": adapter.connected,
	  "adapterIsWifi": true,
	  "networkName": networkName,
	  "networkStrength": networkStrength,
	  "icon": networkIcon,
	  "saved": primaryNetwork.known,
	  "ipAddress": root.ipAddress
	};
	return outputDict;
  }

  function getWifiIcon(strength) {
	if (!(strength > 0))
	  return "󰤭";

	let iconArr = ["󰤟", "󰤢", "󰤥", "󰤨"];
	let strengthIndex = Math.ceil(strength * iconArr.length);
	return iconArr[Math.min(strengthIndex, iconArr.length) - 1];
  }

  function isDeviceWifi(adapter) {
	return adapter.type == DeviceType.Wifi;
  }

  function refreshIpAddress() {
	if (!defaultAdapter) {
	  ipAddress = "";
	  return;
	}

	ipProcess.running = true;
  }

  onDefaultAdapterChanged: refreshIpAddress()
  onConnectedWifiChanged: refreshIpAddress()
  onOnlineChanged: refreshIpAddress()

  Process {
	id: ipProcess

	command: root.defaultAdapter ? ["sh", "-c", "ip -4 -o addr show dev " + root.defaultAdapter.name
	  + " scope global | awk '{sub(\"/.*\", \"\", $4); printf $4}'"] : []
	running: false

	stdout: StdioCollector {
	  onStreamFinished: root.ipAddress = this.text
	}
  }
}
