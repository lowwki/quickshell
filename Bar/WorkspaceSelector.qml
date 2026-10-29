pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import "../Color.js" as Colors
import "../Components/"
import "../Services/"

Container {
  id: root

  property double barHeight: 25
  required property var monitor
  property double rowLeftMargin: 5
  property double workspaceButtonSpacing: 4
  readonly property var workspaces: WorkspaceManager.getWorkspacesForMonitor(monitor)
  readonly property int workspaceCount: workspaces.length
  property double workspaceWidth: 17

  boxHeight: barHeight
  boxRadius: 4
  boxWidth: (2 * rowLeftMargin) + (workspaceCount * workspaceWidth) + ((workspaceCount - 1)
																	   * workspaceButtonSpacing)
  defaultItem: placeholder
  exclusiveMonitor: monitor

  Component {
	id: placeholder

	Item {}
  }

  RowLayout {
	spacing: root.workspaceButtonSpacing

	anchors {
	  bottom: parent.bottom
	  left: parent.left
	  leftMargin: root.rowLeftMargin
	  top: parent.top
	}

	Repeater {
	  delegate: workspaceButton
	  delegateModelAccess: DelegateModel.ReadOnly
	  model: root.workspaces
	}

	Component {
	  id: workspaceButton

	  Item {
		id: buttonRoot

		required property var modelData
		readonly property int stateInt: WorkspaceManager.getWorkspaceStateIndex(modelData)
		property variant workspaceColors: [Colors.lavender, Colors.overlay2, Colors.surface2]
		readonly property var numerals: ["十", "九", "八", "七", "六", "五", "四", "三", "二", "一"]
        
		Layout.alignment: Qt.AlignLeft
		implicitHeight: root.barHeight - 8
		implicitWidth: root.workspaceWidth

		Behavior on implicitHeight {
		  NumberAnimation {
		    duration: 170
		    easing.type: Easing.OutBack
		    easing.overshoot: 0.7
		  }
		}
		Behavior on implicitWidth {
		  NumberAnimation {
		    duration: 170
		    easing.type: Easing.OutBack
		    easing.overshoot: 0.7
		  }
		}

		TapHandler {
		  onTapped: WorkspaceManager.activateWorkspace(buttonRoot.modelData)
		}

		Rectangle {
		  anchors.fill: parent
		  color: buttonRoot.workspaceColors[buttonRoot.stateInt]

          CenteredText {
                yOffset: -0.8
          text: buttonRoot.numerals[buttonRoot.modelData.idx] ?? buttonRoot.modelData.idx
		  }
		}
	  }
	}
  }
}
