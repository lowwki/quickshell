pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import "../Color.js" as Colors
import "../Components/"
import "../Services/"

Container {
  id: root

  required property var monitor
  property double networkDisplayHeight: 80

  animOffset: 250
  boxColor: Colors.red
  boxHeight: 20
  boxHeightOpened: root.networkDisplayHeight
  boxWidth: 25
  boxWidthOpened: 350
  defaultItem: icon
  exclusiveMonitor: root.monitor
  exclusiveToScreen: true
  forceHidden: !NetworkManager.online
  openedItem: networkDisplay

  Component {
	id: icon

	StyledText {
	  horizontalAlignment: Qt.AlignCenter
	  propo: true
	  text: NetworkManager.details["icon"] || "󰤭"
	  verticalAlignment: Qt.AlignVCenter
	}
  }

  Component {
	id: networkDisplay

	Item {
	  id: networkDisplayRoot

	  property double innerMargin: 5
	  property double outerMargin: 6

	  Rectangle {
		id: networkDisplayBg

		anchors.fill: parent
		anchors.margins: networkDisplayRoot.outerMargin
		color: Colors.surface1
		radius: 8

		RowLayout {
		  anchors.fill: parent

		  Rectangle {
			id: iconBox

			Layout.fillHeight: true
			Layout.margins: networkDisplayRoot.innerMargin
			color: Colors.red
			implicitWidth: root.networkDisplayHeight - (networkDisplayRoot.innerMargin * 2) - (
							 networkDisplayRoot.outerMargin * 2)
			radius: 5

			CenteredText {
			  fontSize: 23
			  propo: true
			  text: NetworkManager.details["icon"]
			}
		  }

		  Column {
			id: networkColumn

			property var networkInfo: NetworkManager.details

			Layout.alignment: Qt.AlignVCenter
			Layout.fillWidth: true

			StyledText {
			  color: Colors.text
			  fontSize: 14
			  text: networkColumn.networkInfo["networkName"]
			}

			StyledText {
			  color: Colors.subtext1
			  fontSize: 12
			  fontWeight: 5
			  text: networkColumn.networkInfo["ipAddress"] + " on "
			  + networkColumn.networkInfo["adapterName"]
			}

			StyledText {
			  color: Colors.subtext1
			  fontSize: 12
			  fontWeight: 5
			  text: "Network Details " + (networkColumn.networkInfo["saved"] == true ? "Saved" : "Not Saved")
			}
		  }
		}
	  }
	}
  }
}
