pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import "./Bar"
import "./Services/"
import "Color.js" as Colors

Scope {
  Variants {
    delegate: panelWindow
    model: Quickshell.screens
  }

  Component {
    id: panelWindow

    PanelWindow {
      id: win

      required property var modelData

      color: "transparent"
      exclusionMode: ExclusionMode.Normal
      exclusiveZone: IpcManager.tabletMode ? 35 : 7
      // Tall enough for the largest popup (notification, media toast, device lists).
      // Input outside the mask regions below passes straight through to windows underneath.
      implicitHeight: 400
      mask: maskRegion
      screen: modelData

      anchors {
        left: true
        right: true
        top: true
      }

      Region {
        id: maskRegion

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
          leftMargin: 3
          rightMargin: 3
          topMargin: 3
        }

        Row {
          id: left

          anchors {
            left: parent.left
            top: parent.top
          }

          WorkspaceSelector {
            monitor: win.modelData
          }
        }

        Row {
          id: center

          anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
          }

          Time {
            monitor: win.modelData
          }
        }

        Row {
          id: right

          spacing: 5

          anchors {
            right: parent.right
            top: parent.top
          }

          Network {
            monitor: win.modelData
          }

          Bluetooth {
            monitor: win.modelData
          }

          Battery {
            monitor: win.modelData
          }
        }
      }
    }
  }
}
