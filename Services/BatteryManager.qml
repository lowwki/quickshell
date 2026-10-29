pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
  id: root

  property bool hasLaptopBattery: !!mainBattery && mainBattery.isLaptopBattery
  property UPowerDevice mainBattery: UPower.displayDevice || undefined
  // 0-100, or 0 when there is no battery
  readonly property double percent: mainBattery ? mainBattery.percentage * 100 : 0

  function formatRemaining(seconds, suffix) {
    if (seconds == 0)
      return "Getting Time...";

    const t = secondsToTime(seconds);
    const parts = (t.hours >= 1 || t.hourNeedsIncrement)
      ? [(t.hours + (t.hourNeedsIncrement ? 1 : 0)) + " Hours", t.minutesRounded > 0 ? t.minutesRounded + " Minutes" : ""]
      : [t.minutes + " Minutes", t.seconds + " Seconds"];

    return parts.filter(part => part).join(" ") + suffix;
  }

  function getBatteryName(battery) {
    const parts = (battery.nativePath || "").split("/");
    return parts[parts.length - 1];
  }

  function getChargingRateFormat() {
    if (!mainBattery)
      return "Battery Idle";

    const rate = mainBattery.changeRate.toFixed(1);
    if (rate == 0)
      return "Battery Idle";

    const charging = rate <= 0 || mainBattery.state == UPowerDeviceState.Charging;
    return (charging ? "Charging" : "Discharging") + " at " + rate + "W";
  }

  function getMainBatteryInfo() {
    const battery = UPower.devices.values[0];
    if (!battery)
      return { "name": "", "charge": 0, "energy": "0.0", "capacity": "0.0", "health": 0 };

    return {
      "name": getBatteryName(battery),
      "charge": battery.percentage,
      "energy": battery.energy.toFixed(1),
      "capacity": battery.energyCapacity.toFixed(1),
      "health": battery.healthPercentage
    };
  }

  function getTimeFormat() {
    if (!mainBattery)
      return "Getting Time...";

    const state = mainBattery.state;
    if (state == UPowerDeviceState.FullyCharged)
      return "Battery Full";
    if (state == UPowerDeviceState.Charging)
      return formatRemaining(mainBattery.timeToFull, " Until Full");
    if (state == UPowerDeviceState.Discharging)
      return formatRemaining(mainBattery.timeToEmpty, " Remaining");

    return "Getting Time...";
  }

  function secondsToTime(totalSeconds) {
    totalSeconds = Math.max(0, Number(totalSeconds));

    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = Math.floor(totalSeconds % 60);

    const roundedMinutes = minutes + (seconds >= 30 ? 1 : 0);
    const hourNeedsIncrement = roundedMinutes === 60;

    return {
      hours,
      minutes,
      seconds,
      minutesRounded: hourNeedsIncrement ? 0 : roundedMinutes,
      hourNeedsIncrement
    };
  }
}
