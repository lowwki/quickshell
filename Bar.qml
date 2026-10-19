pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./Bar"
import "./Services/"
import "Color.js" as Colors

Scope {
  Variants {
	id: panelDelegate

	delegate: panelWindow
	model: Quickshell.screens
  }

  Component {
	id: panelWindow

	PanelWindow {
	  id: win

	  property double barExclusionZone: IpcManager.tabletMode ? 35 : 7
	  property double barMaxHeight: modelData.height
	  required property var modelData
	  // niri: the screen itself stands in for the monitor object
	  property var monitor: modelData
	  property bool monitorFocused: NiriService.focusedOutput === modelData.name

	  WlrLayershell.keyboardFocus: monitorFocused ? IpcManager.focusState :
															 WlrKeyboardFocus.None
	  color: "transparent"
	  exclusionMode: ExclusionMode.Normal
	  exclusiveZone: barExclusionZone
	  implicitHeight: barMaxHeight
	  mask: maskRegion
	  screen: modelData

	  Rectangle {
		id: blurOverlay

		color: Colors.base
		implicitHeight: win.modelData.height
		implicitWidth: win.modelData.width
		opacity: IpcManager.logoutMenuOpen == true ? 0.8 : 0

		Behavior on opacity {
		  NumberAnimation {
			duration: 200
		  }
		}
	  }

    
    Region {
        id: maskRegion

        Region {
            item: launcher
    }

    Region {
		  item: left
    }
    
    Region {
		  item: center
		}
  
    Region {
		  item: right
		}
	  }

	  anchors {
		left: true
		right: true
		top: true
	  }

	  MultiEffect {
		 anchors.fill: rowContainer
		 shadowBlur: 1
		 shadowColor: Colors.mantle
		 shadowEnabled: true
		 shadowHorizontalOffset: 3
		 shadowOpacity: 1
		 shadowVerticalOffset: 1
		 source: rowContainer
		}

	  Item {
		id: rowContainer

		anchors {
		  fill: parent
		  topMargin: 3
		}

		anchors {
		  left: parent.left
		  leftMargin: 3
		  right: parent.right
		  rightMargin: 3
		  top: parent.top
		}

		Launcher {
		   id: launcher
		 }

		Row {
		  id: left

		  anchors {
			left: parent.left
			top: parent.top
		  }

		  WorkspaceSelector {
			monitor: win.monitor
		  }
		}

		Row {
		  id: center

		  anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
		  }

		  Time {
			monitor: win.monitor
		  }
		}

		Row {
		  id: right

		  Layout.alignment: Qt.AlignTop
		  spacing: 5

		  anchors {
			right: parent.right
			top: parent.top
		  }

		  Network {
			monitor: win.monitor
		  }

		  Bluetooth {
			monitor: win.monitor
		  }

		  Battery {
			monitor: win.monitor
		  }
		}
	  }
	}
  }
}
