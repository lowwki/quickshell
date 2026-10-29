pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
  id: root

  property BluetoothAdapter defaultAdapter: Bluetooth.defaultAdapter || null

  // Connected devices of the default adapter, computed once and shared by every consumer
  readonly property var connectedDevices: {
    const connected = [];
    if (!defaultAdapter)
      return connected;

    for (const device of defaultAdapter.devices.values) {
      if (device.connected)
        connected.push(device);
    }
    return connected;
  }
  readonly property bool anyConnected: connectedDevices.length > 0

  function getDeviceText(device) {
	if (!device) {
	  return undefined;
	}
	let deviceName = device.deviceName;
	let deviceIcon = getIcon(device.icon);
	let deviceMac = device.address;
	let hasBattery = device.batteryAvailable;
	let deviceBattery = deviceIcon;
	let deviceBatteryRaw = 0;
	if (hasBattery) {
	  deviceBattery = device.battery * 100;
	  deviceBatteryRaw = device.battery;
	}

	return {
	  "icon": deviceIcon,
	  "name": deviceName,
	  "mac": deviceMac,
	  "hasBattery": hasBattery,
	  "battery": deviceBattery,
	  "batteryRaw": deviceBatteryRaw
	};
  }

  function getIcon(name) {
	const icons = {
	  "audio-card": "󰓃",
	  "audio-input-microphone": "",
	  "audio-headphones": "󰋋",
	  "audio-headset": "󰋋",
	  "battery": "󰂀",
	  "camera-photo": "󰻛",
	  "computer": "",
	  "input-keyboard": "󰌌",
	  "input-mouse": "󰍽",
	  "input-gaming": "󰊴",
	  "phone": "󰏲"
	};

	return icons[name] || "󰾰";
  }
}
