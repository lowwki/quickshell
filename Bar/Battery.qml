pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import "../Color.js" as Colors
import "../Components/"
import "../Services/"

Container {
  id: root

  property double batteryDisplayHeight: 100
  required property var monitor
  property bool opened: false
  property double radius: 4

  animOffset: 150
  boxColor: Colors.green
  boxHeight: 20
  boxHeightOpened: root.batteryDisplayHeight
  boxRadius: radius
  boxWidth: 30
  boxWidthOpened: 450
  defaultItem: icon
  exclusiveMonitor: root.monitor
  exclusiveToScreen: true
  forceHidden: !BatteryManager.hasLaptopBattery
  openedItem: batteryDisplay

  Component {
	id: icon

	Item {
	  property string component: "icon"

	  // Icon and percentage are separate items so the pair can be centered and aligned precisely
	  Row {
		anchors.centerIn: parent
		spacing: 4

		// StyledText {
		//   anchors.verticalCenter: parent.verticalCenter
		//   fontSize: 10
		//   horizontalAlignment: Text.AlignHCenter
		//   propo: true
		//   text: BatteryManager.getBatteryIcon(BatteryManager.mainBattery) || ""
		//   verticalAlignment: Text.AlignVCenter
		// }

		StyledText {
		  anchors.verticalCenter: parent.verticalCenter
		  fontSize: 11
		  horizontalAlignment: Text.AlignHCenter
		  text: Math.round(BatteryManager.getBatteryPercentage(BatteryManager.mainBattery))  // + "%";
 		  verticalAlignment: Text.AlignVCenter
		}
	  }
	}
  }

  Component {
	id: batteryDisplay

	Item {
	  id: batteryDisplayRoot

	  property double innerMargin: 5
	  property double outerMargin: 6

	  Rectangle {
		id: batteryBackground

		anchors.fill: parent
		anchors.margins: batteryDisplayRoot.outerMargin
		color: Colors.surface1
		radius: 8

		RowLayout {
		  anchors.fill: parent

		  Rectangle {
			id: percentBox

			property double percentBoxRadius: 5

			Layout.fillHeight: true
			Layout.margins: batteryDisplayRoot.innerMargin
			color: Colors.text
			implicitWidth: root.batteryDisplayHeight - (batteryDisplayRoot.innerMargin * 2) - (
							 batteryDisplayRoot.outerMargin * 2)
			radius: 5

			Rectangle {
			  color: Colors.green
			  implicitHeight: (root.batteryDisplayHeight - (batteryDisplayRoot.innerMargin * 2) - (
								 batteryDisplayRoot.outerMargin * 2)) * BatteryManager.mainBattery.percentage
			  radius: percentBox.percentBoxRadius

			  anchors {
				bottom: parent.bottom
				left: parent.left
				right: parent.right
			  }
			}

			CenteredText {
			  fontSize: 15
			  text: BatteryManager.getBatteryPercentage(BatteryManager.mainBattery) + "%"
			}
		  }

		  Column {
			id: batColumn

			property var batInfo: BatteryManager.getMainBatteryInfo()

			Layout.alignment: Qt.AlignVCenter
			Layout.fillWidth: true

			StyledText {
			  color: Colors.text
			  fontSize: 14
			  text: "Battery - " + batColumn.batInfo["name"]
			}

			StyledText {
			  color: Colors.subtext1
			  fontSize: 12
			  fontWeight: 5
			  text: batColumn.batInfo["energy"] + "/" + batColumn.batInfo["capacity"] + "Wh - "
			  + BatteryManager.getChargingRateFormat()
			}

			StyledText {
			  property var timeInfo: batColumn.batInfo["time"]

			  color: Colors.subtext1
			  fontSize: 12
			  fontWeight: 5
			  text: BatteryManager.getTimeFormat()
			}
		  }
		}
	  }
	}
  }
}
