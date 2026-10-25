import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell

import "../Color.js" as Colors
import "../Services/"

Item {
  id: root

  property bool _fullyHidden: false                                       // properties of the containerboxes.
  property bool _widthCollapsed: false
  property double animOffset: 0
  property color boxColor: Colors.surface0
  property double boxHeight: 28
  property double boxHeightOpened: 150
  property bool boxOpened: false
  property double boxRadius: 4
  property double boxRadiusOpened: 10
  property double boxWidth: 100
  property double boxWidthOpened: 200
  readonly property double calculatedTopMargin: {
	if (!root.exclusiveToScreen) {
	  return visibleTopMargin;
	}

	if (NiriService.isFocused(root.exclusiveMonitor)) {
	  if (!root.forceHidden) {
		return visibleTopMargin;
	  } else if (root.hoverableWhenHidden) {
		return 7 - root.boxHeight - 5;
	  }
	}

	return -4 - root.boxHeight - 5;
  }
  property Component defaultItem
  required property var exclusiveMonitor
  property bool exclusiveToScreen: false
  property bool forceHidden: false
  property alias hover: hoverHandler
  property bool hoverableWhenHidden: false
  property bool hovered: false
  property Component openedItem
  property bool overriden: false
  property int popDuration: 185                                           // shared by width, height and radius
  property real popOvershoot: 0.8
  property alias rect: container
  property alias stack: containerContent
  property alias tap: tapHandler
  property double visibleTopMargin: 0

  implicitHeight: boxHeight
  implicitWidth: root._widthCollapsed ? 0 : root.boxWidth
  visible: !root._fullyHidden

  Behavior on anchors.topMargin {
	animation: defaultCurve
 }
  // Width, height and corner radius use the same duration and easing, so the box grows
  // as one shape. The radius is animated only once, by container.radius below; it used to
  // be animated here as well, which made the corners trail behind the size.
  Behavior on implicitHeight {
    NumberAnimation {
      duration: root.popDuration
      easing.overshoot: root.popOvershoot
      easing.type: Easing.OutBack
    }
  }

  Behavior on implicitWidth {
    NumberAnimation {
      duration: root.popDuration
      easing.overshoot: root.popOvershoot
      easing.type: Easing.OutBack
    }
  }
  states: [
	State {
	  name: "closed"
	  when: root.hovered == false && root.boxOpened == false && root.overriden == false
			&& IpcManager.tabletMode == false

	  PropertyChanges {
		container.radius: root.boxRadius
		root.implicitHeight: root.boxHeight
		root.implicitWidth: root.boxWidth
	  }

	  StateChangeScript {
		script: {
		  stack.replace(root.defaultItem);
		}
	  }
	},
	State {
	  name: "tablet"
	  when: ( root.hovered == false || IpcManager.tabletMode == true ) && root.boxOpened == false && root.overriden == false
			&& IpcManager.tabletMode == true

	  PropertyChanges {
		container.radius: root.boxRadius
		root.implicitHeight: 33
		root.implicitWidth: root.boxWidth
	  }

	  StateChangeScript {
		script: {
		  stack.replace(root.defaultItem);
		}
	  }
	},
	State {
	  name: "hovered"
	  when: root.hovered == true && root.boxOpened == false && root.overriden == false

	  PropertyChanges {
		container.radius: root.boxRadius + 3
		root.implicitHeight: IpcManager.tabletMode ? 35 : root.boxHeight + 2
		root.implicitWidth: root.boxWidth + 2
	  }

	  StateChangeScript {
		script: {
		  if (IpcManager.tabletMode == false) {
			stack.replace(root.defaultItem);
		  }
		}
	  }
	},
	State {
	  name: "opened"
	  when: root.boxOpened == true && root.hovered == true && root.overriden == false

	  PropertyChanges {
		container.radius: root.boxRadiusOpened
		root.implicitHeight: root.boxHeightOpened
		root.implicitWidth: root.boxWidthOpened
	  }

	  StateChangeScript {
		script: {
		  stack.replace(root.openedItem);
		}
	  }
	}
  ]

  onForceHiddenChanged: {
	if (root.forceHidden == true) {
	  hideTimer.restart();
	} else {
	  hideTimer.stop();
	  subHideTimer.stop();
	  root._fullyHidden = false;
	  root._widthCollapsed = false;
	}
  }

  Timer {
	id: hideTimer

	interval: 250
	repeat: false
	running: false

	onTriggered: {
	  root._widthCollapsed = true;
	  subHideTimer.restart();
	}
  }

  Timer {
	id: subHideTimer

	interval: 200
	repeat: false
	running: false

	onTriggered: {
	  root._fullyHidden = true;
	}
  }

  anchors {
	top: parent.top
	topMargin: calculatedTopMargin
  }

  NumberAnimation {
	id: defaultCurve

	duration: 200 + root.animOffset
	easing: Easing.InOutBack
  }

  HoverHandler {
	id: hoverHandler

	onHoveredChanged: {
	  if (hoverHandler.hovered == true) {
		root.hovered = true;
	  } else {
		root.hovered = false;
		root.boxOpened = false;
		if (root.state == "closed" || root.state == "tablet") {
		  if (IpcManager.tabletMode == false) {
			root.stack.replace(root.defaultItem);
			console.log("some");
		  }
		}
	  }
	}
  }

  TapHandler {
	id: tapHandler

	onTapped: {
	  if (root.openedItem) {
		root.boxOpened = true;
	  }
	}
  }

  TapHandler {
	id: touchScreenTapHandler

	acceptedDevices: PointerDevice.TouchScreen

	onGrabChanged: state => {
					 if (state == 1) {
					   if (root.openedItem) {
						 root.hovered = true;
						 root.boxOpened = true;
					   }
					 } else if (state == 2) {
					   root.hovered = false;
					   root.boxOpened = false;
					 }
				   }
  }

  Rectangle {
	id: container

	anchors.fill: parent
	clip: true
	color: root.boxColor
	radius: root.boxRadius

	Behavior on radius {
	  NumberAnimation {
		duration: root.popDuration
		easing.type: Easing.OutBack
		easing.overshoot: root.popOvershoot
	  }
	}

	StackView {
	  id: containerContent

	  anchors.fill: parent

	  replaceEnter: Transition {
		PropertyAnimation {
		  duration: 100
		  from: 0
		  property: "opacity"
		  to: 1
		}

		PropertyAnimation {
		  duration: 100
		  from: -5
		  property: "anchors.topMargin"
		  to: 0
		}
	  }
	  replaceExit: Transition {
		PropertyAnimation {
		  duration: 100
		  from: 1
		  property: "opacity"
		  to: 0
		}
	  }

	  Component.onCompleted: containerContent.push(root.defaultItem)
	  onCurrentItemChanged: {
		if (currentItem) {
		  // Dynamically center the incoming child to the StackView
		  currentItem.anchors.horizontalCenter = containerContent.horizontalCenter;
		  currentItem.anchors.verticalCenter = containerContent.verticalCenter;
		}
	  }
	}
  }
}
