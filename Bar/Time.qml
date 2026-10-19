pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Widgets

import "../Color.js" as Colors
import "../Components/"
import "../Services/"

Container {
  id: root

  property Notification latestNotif
  property bool logout: false
  property double logoutHeight: 100
  property double logoutMargin: 7
  property double logoutSpacing: 5
  required property var monitor
  property bool mpris: false
  property double mprisHeight: 76
  property bool mprisPlaying: MprisManager.getPlaying()
  property double mprisWidth: 350
  property double notificationHeight: 100
  property double notificationWidth: 350
  property bool notified: false

  boxColor: Colors.mauve
  boxHeight: 20
  boxWidth: IpcManager.tabletMode ? 600 : 60
  defaultItem: IpcManager.tabletMode ? tabletTime : time
  exclusiveMonitor: root.monitor
  exclusiveToScreen: true

  states: [
    State {
      name: "notified"
      when: root.notified == true

      PropertyChanges {
        root.boxHeight: root.notificationHeight
        root.boxRadius: 12
        root.boxWidth: root.notificationWidth
        root.visibleTopMargin: 5
      }

      StateChangeScript {
        script: {
          root.stack.replace(notification);
          notificationTimer.restart();
        }
      }
    },
    State {
      name: "mpris"
      when: root.mpris == true

      PropertyChanges {
        root.boxHeight: root.mprisHeight
        root.boxRadius: 12
        root.boxWidth: root.mprisWidth
        root.visibleTopMargin: root.hovered == true ? 0 : 5
      }

      StateChangeScript {
        script: {
          root.stack.replace(mprisToast);
        }
      }
    }
    // State {
    //   name: "logout"
    //   when: root.logout == true
    //
    //   PropertyChanges {
    //     root.boxHeight: root.logoutHeight
    //     root.boxRadius: 13
    //     root.boxWidth: ((root.logoutHeight - (root.logoutMargin * 2)) * 5) + (root.logoutMargin * 2) + (
    //                      root.logoutSpacing * 4)
    //     root.visibleTopMargin: 10
    //   }
    //
    //   StateChangeScript {
    //     script: {
    //       root.stack.replace(logoutMenu);
    //     }
    //   }
    // }
  ]

  // Closes the mpris toast (never touches an active notification)
  function closeMpris() {
    if (root.mpris == false) {
      return;
    }

    root.mpris = false;

    if (root.notified == false) {
      root.overriden = false;
    }
  }

  // Toast shows only while hovering AND something is playing
  onHoveredChanged: {
    if (root.hovered == true) {
      if (root.logout == false && root.notified == false && MprisManager.getPlaying() == true) {
        root.overriden = true;
        root.mpris = true;
      }
    } else {
      root.closeMpris();
    }
  }

  // Pause/stop/player gone closes it; playback starting under the cursor opens it
  onMprisPlayingChanged: {
    if (root.mprisPlaying == false) {
      root.closeMpris();
    } else if (root.hovered == true && root.logout == false && root.notified == false) {
      root.overriden = true;
      root.mpris = true;
    }
  }

  Connections {
    function onNewNotification(notification) {
      if (notification.lastGeneration == false) {
        root.latestNotif = notification;
        root.overriden = true;
        root.notified = true;
      }
    }

    target: NotificationManager
  }

  Timer {
    id: notificationTimer

    interval: 5000
    repeat: false
    running: false

    onTriggered: {
      root.notified = false;
      root.overriden = false;
    }
  }

  // Component {
  //   id: logoutMenu
  //
  //   Item {
  //     id: logoutMenuRoot
  //
  //     property var logoutModel: [
  //       {
  //         color: Colors.red,
  //         text: "\uf011",
  //         key: Qt.Key_S,
  //         command: ["systemctl", "poweroff"]
  //       },
  //       {
  //         color: Colors.peach,
  //         text: "󰗽",
  //         key: Qt.Key_E,
  //         command: ["niri", "msg", "action", "quit", "--skip-confirmation"]
  //       },
  //       {
  //         color: Colors.yellow,
  //         text: "󰑓",
  //         key: Qt.Key_R,
  //         command: ["systemctl", "reboot"]
  //       },
  //       {
  //         color: Colors.green,
  //         text: "󰌾",
  //         key: Qt.Key_L,
  //         command: ["hyprlock"]
  //       },
  //       {
  //         color: Colors.sky,
  //         text: "󰤄",
  //         key: Qt.Key_U,
  //         command: ["systemctl", "suspend"]
  //       },
  //     ]
  //
  //     Component.onCompleted: {
  //       forceActiveFocus();
  //     }
  //
  //     Keys.onPressed: event => {
  //       if (event.key == Qt.Key_Escape) {
  //         IpcManager.closeLogoutMenu();
  //       } else {
  //         for (let button of logoutMenuRoot.logoutModel) {
  //           if (button.key == event.key) {
  //             IpcManager.closeLogoutMenu();
  //             event.accepted = true;
  //             Quickshell.execDetached(button.command);
  //           }
  //         }
  //       }
  //     }
  //
  //     RowLayout {
  //       spacing: root.logoutSpacing
  //
  //       anchors {
  //         fill: parent
  //         margins: root.logoutMargin
  //       }
  //
  //       Repeater {
  //         delegate: logoutButton
  //         model: logoutMenuRoot.logoutModel
  //       }
  //
  //       Component {
  //         id: logoutButton
  //
  //         Item {
  //           id: logoutButtonRoot
  //
  //           required property var modelData
  //
  //           Layout.fillHeight: true
  //           Layout.fillWidth: true
  //
  //           HoverHandler {
  //             id: logoutHoverHandler
  //
  //             onHoveredChanged: {
  //               if (logoutHoverHandler.hovered == true) {
  //                 buttonBackground.color = Colors.surface1;
  //                 logoutButtonText.color = logoutButtonRoot.modelData.color;
  //               } else {
  //                 buttonBackground.color = logoutButtonRoot.modelData.color;
  //                 logoutButtonText.color = Colors.base;
  //               }
  //             }
  //           }
  //
  //           TapHandler {
  //             onTapped: {
  //               Quickshell.execDetached(logoutButtonRoot.modelData.command);
  //             }
  //           }
  //
  //           Rectangle {
  //             id: buttonBackground
  //
  //             anchors.fill: parent
  //             color: logoutButtonRoot.modelData.color
  //             radius: 7
  //
  //             Behavior on color {
  //               ColorAnimation {
  //                 duration: 100
  //               }
  //             }
  //
  //             StyledText {
  //               id: logoutButtonText
  //
  //               anchors.fill: parent
  //               fontSize: 25
  //               horizontalAlignment: Qt.AlignHCenter
  //               propo: true
  //               text: logoutButtonRoot.modelData.text
  //               verticalAlignment: Qt.AlignVCenter
  //
  //               Behavior on color {
  //                 ColorAnimation {
  //                   duration: 100
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  // }

  Component {
    id: time

    StyledText {
      property string component: "time"

      horizontalAlignment: Qt.AlignCenter
      text: TimeManager.time
      verticalAlignment: Qt.AlignVCenter
    }
  }

  Component {
    id: tabletTime

    Item {
      property string component: "tabletTime"

      Rectangle {
        color: Colors.surface1
        radius: root.boxRadius - 2

        anchors {
          fill: parent
          margins: 3
          topMargin: 3
        }

        Component {
          id: tabletButton

          Rectangle {
            id: tabletButtonRoot

            required property var modelData

            color: Colors.overlay0
            implicitWidth: 25
            radius: root.boxRadius - 4

            Behavior on color {
              ColorAnimation {
                duration: 60
              }
            }

            anchors {
              bottom: parent.bottom
              top: parent.top
            }

            TapHandler {
              onTapped: {
                tabletButtonRoot.modelData.onTapped();
                tabletButtonRoot.color = Colors.text;
                tapAnimationTimer.restart();
              }
            }

            Timer {
              id: tapAnimationTimer

              interval: 80
              repeat: false
              running: false

              onTriggered: {
                tabletButtonRoot.color = Colors.overlay0;
              }
            }

            StyledText {
              anchors.fill: parent
              color: Colors.mauve
              fontSize: 14
              fontWeight: 10
              horizontalAlignment: Qt.AlignHCenter
              propo: true
              text: tabletButtonRoot.modelData.text
              verticalAlignment: Qt.AlignVCenter
            }
          }
        }

        Row {
          anchors {
            bottom: parent.bottom
            bottomMargin: 3
            left: parent.left
            leftMargin: 4
            top: parent.top
            topMargin: 3
          }

          // Repeater {
          //   delegate: tabletButton
          //   model: [
          //     {
          //       text: "󱗿",
          //       onTapped: function () {
          //         IpcManager.toggleLauncher();
          //       }
          //     },
          //   ]
          // }
        }

        CenteredText {
          color: Colors.mauve
          text: TimeManager.time
        }

        Row {
          spacing: 3

          anchors {
            bottom: parent.bottom
            bottomMargin: 3
            right: parent.right
            rightMargin: 4
            top: parent.top
            topMargin: 3
          }

          Repeater {
            delegate: tabletButton
            model: [
              {
                text: "\uf060",
                onTapped: function () {
                  WorkspaceManager.focusPrevious();
                }
              },
              {
                text: "\uf061",
                onTapped: function () {
                  WorkspaceManager.focusNext();
                }
              },
            ]
          }
        }
      }
    }
  }

  Component {
    id: notification

    Item {
      id: notificationRoot

      property double innerMargin: 5
      property double outerMargin: 2

      // Real picture (screenshot, avatar, album art). It can arrive in `image`,
      // or as a file path in `appIcon` (what notify-send -i <file> does).
      // Empty when the notification only has a themed app icon.
      readonly property string thumbSource: {
        let n = root.latestNotif;
        if (!n)
          return "";
        let s = n.image || n.appIcon || "";
        if (s.startsWith("/"))
          return "file://" + s;
        if (s.startsWith("file://") || s.startsWith("image://") || s.startsWith("qrc:"))
          return s;
        return "";
      }

      function getInnerHeight() {
        let fullHeight = root.notificationHeight;
        let fullMargin = notificationRoot.innerMargin + notificationRoot.outerMargin;

        return fullHeight - (fullMargin * 2);
      }

      Rectangle {
        color: Colors.surface1
        radius: 9

        anchors {
          fill: parent
          margins: notificationRoot.outerMargin
        }

        RowLayout {
          anchors.fill: parent

          ClippingRectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.margins: notificationRoot.innerMargin
            Layout.preferredHeight: notificationRoot.getInnerHeight()
            Layout.preferredWidth: notificationRoot.getInnerHeight()
            color: Colors.mauve
            radius: 6

            // real picture: fill the whole square and crop to the rounded corners
            Image {
              anchors.fill: parent
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
              source: notificationRoot.thumbSource
              visible: notificationRoot.thumbSource != ""
            }

            // themed app icon: keep a small margin around it
            IconImage {
              anchors.fill: parent
              anchors.margins: 8
              source: root.latestNotif.appIcon ? Quickshell.iconPath(root.latestNotif.appIcon, true) : ""
              visible: notificationRoot.thumbSource == ""
            }
          }

          ColumnLayout {
            property double textMargin: 4

            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.leftMargin: 0
            Layout.margins: notificationRoot.innerMargin + textMargin

            StyledText {
              Layout.fillWidth: true
              color: Colors.text
              elide: Qt.ElideRight
              fontSize: 14
              text: root.latestNotif.summary
            }

            StyledText {
              Layout.fillHeight: true
              Layout.fillWidth: true
              color: Colors.subtext0
              elide: Qt.ElideRight
              fontWeight: 5
              maximumLineCount: 2
              text: root.latestNotif.body
              wrapMode: Text.WordWrap
            }
          }
        }
      }
    }
  }

  Component {
    id: mprisToast

    Item {
      id: mprisToastRoot

      property double artSize: root.mprisHeight - ((innerMargin + outerMargin) * 2)
      property bool debug: true
      property real dragProgress: 0
      property bool dragging: false
      // Some players (Firefox) don't report a real track length; then there is nothing to seek within
      readonly property bool hasLength: player != null && player.lengthSupported && player.length > player.position + 0.5
      property double innerMargin: 5
      readonly property real length: hasLength ? player.length : 0
      property double outerMargin: 2
      readonly property var player: MprisManager.defaultPlayer
      readonly property real position: player ? Math.max(0, player.position) : 0
      readonly property real progress: length > 0 ? Math.min(1, position / length) : 0
      readonly property bool seekable: hasLength && player.positionSupported && player.canSeek
      readonly property real shownProgress: dragging ? dragProgress : progress

      function formatTime(seconds) {
        let total = Math.floor(Math.max(0, seconds));
        let h = Math.floor(total / 3600);
        let m = Math.floor((total % 3600) / 60);
        let s = total % 60;
        let ss = (s < 10 ? "0" : "") + s;

        if (h > 0) {
          return h + ":" + (m < 10 ? "0" : "") + m + ":" + ss;
        }
        return m + ":" + ss;
      }

      // The player position is not pushed automatically, so poll it while playing
      Timer {
        interval: 500
        repeat: true
        running: mprisToastRoot.player != null && root.mprisPlaying
        triggeredOnStart: true

        onTriggered: mprisToastRoot.player.positionChanged()
      }

      // After a seek, wait a moment, refresh the position, then hand the handle back
      Timer {
        id: settleTimer

        interval: 700
        repeat: false

        onTriggered: {
          mprisToastRoot.player.positionChanged();
          mprisToastRoot.dragging = false;
        }
      }

      // TEMPORARY: set debug to false once the timeline behaves
      Timer {
        interval: 1000
        repeat: true
        running: mprisToastRoot.debug && mprisToastRoot.player != null

        onTriggered: console.log("mpris-debug:", mprisToastRoot.player.identity,
                                 "length=" + mprisToastRoot.player.length,
                                 "position=" + mprisToastRoot.player.position,
                                 "lengthSupported=" + mprisToastRoot.player.lengthSupported,
                                 "positionSupported=" + mprisToastRoot.player.positionSupported,
                                 "canSeek=" + mprisToastRoot.player.canSeek)
      }

      Rectangle {
        color: Colors.surface1
        radius: 9

        anchors {
          fill: parent
          margins: mprisToastRoot.outerMargin
        }

        RowLayout {
          spacing: 9

          anchors {
            fill: parent
            margins: mprisToastRoot.innerMargin
          }

          ClippingRectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: mprisToastRoot.artSize
            Layout.preferredWidth: mprisToastRoot.artSize
            color: Colors.surface2
            radius: 6

            Image {
              anchors.fill: parent
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
              source: mprisToastRoot.player ? (mprisToastRoot.player.trackArtUrl ?? "") : ""
            }
          }

          ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 1

            // Title + artist on the left, transport controls on the right
            RowLayout {
              Layout.fillWidth: true
              spacing: 4

              ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: 1
                spacing: 0

                StyledText {
                  Layout.fillWidth: true
                  Layout.minimumWidth: 0
                  color: Colors.text
                  fontSize: 10
                  fontWeight: 7
                  text: mprisToastRoot.player ? mprisToastRoot.player.trackTitle : ""
                }

                StyledText {
                  Layout.fillWidth: true
                  Layout.minimumWidth: 0
                  color: Colors.subtext0
                  fontSize: 8
                  fontWeight: 5
                  text: mprisToastRoot.player ? mprisToastRoot.player.trackArtist : ""
                }
              }

              Row {
                Layout.alignment: Qt.AlignVCenter

                MediaButton {
                  enabled: mprisToastRoot.player ? mprisToastRoot.player.canGoPrevious : false
                  glyph: "󰒮" // nf-md-skip_previous

                  onClicked: MprisManager.prev()
                }

                MediaButton {
                  glyph: root.mprisPlaying ? "󰏤" : "󰐊" // nf-md-pause / nf-md-play

                  onClicked: MprisManager.togglePlaying()
                }

                MediaButton {
                  enabled: mprisToastRoot.player ? mprisToastRoot.player.canGoNext : false
                  glyph: "󰒭" // nf-md-skip_next

                  onClicked: MprisManager.skip()
                }
              }
            }

            // Android style slider: rounded track, gap, thin handle
            Item {
              id: seekBar

              readonly property double gap: 3
              readonly property double trackHeight: 5

              Layout.fillWidth: true
              Layout.preferredHeight: 14

              Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.lavender
                height: seekBar.trackHeight
                radius: height / 2
                width: Math.max(0, seekHandle.x - seekBar.gap)
              }

              Rectangle {
                id: seekHandle

                anchors.verticalCenter: parent.verticalCenter
                color: Colors.lavender
                height: seekBar.height
                radius: width / 2
                width: 3
                x: Math.min(seekBar.width - width, Math.max(0, (seekBar.width * mprisToastRoot.shownProgress) - (width / 2)))

                Behavior on x {
                  enabled: !mprisToastRoot.dragging

                  NumberAnimation {
                    duration: 450
                  }
                }
              }

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.surface2
                height: seekBar.trackHeight
                radius: height / 2
                width: Math.max(0, seekBar.width - x)
                x: seekHandle.x + seekHandle.width + seekBar.gap
              }

              MouseArea {
                id: seekArea

                // taller hit area than the visible bar so it is easy to grab
                anchors.bottomMargin: -5
                anchors.fill: parent
                anchors.topMargin: -5
                enabled: mprisToastRoot.seekable
                preventStealing: true

                function fractionAt(x) {
                  return Math.max(0, Math.min(1, x / seekBar.width));
                }

                onCanceled: mprisToastRoot.dragging = false
                onPositionChanged: mouse => {
                  if (seekArea.pressed) {
                    mprisToastRoot.dragProgress = seekArea.fractionAt(mouse.x);
                  }
                }
                onPressed: mouse => {
                  settleTimer.stop();
                  mprisToastRoot.dragProgress = seekArea.fractionAt(mouse.x);
                  mprisToastRoot.dragging = true;
                }
                onReleased: mouse => {
                  mprisToastRoot.dragProgress = seekArea.fractionAt(mouse.x);
                  mprisToastRoot.player.position = mprisToastRoot.dragProgress * mprisToastRoot.length;
                  // hold the handle in place until the player reports the new position
                  settleTimer.restart();
                }
              }
            }

            // Elapsed / total, small text
            RowLayout {
              Layout.fillWidth: true

              StyledText {
                color: Colors.subtext0
                fontSize: 7
                fontWeight: 5
                text: mprisToastRoot.formatTime(mprisToastRoot.dragging ? mprisToastRoot.dragProgress * mprisToastRoot.length : mprisToastRoot.position)
              }

              Item {
                Layout.fillWidth: true
              }

              StyledText {
                color: Colors.subtext0
                fontSize: 7
                fontWeight: 5
                text: mprisToastRoot.hasLength ? mprisToastRoot.formatTime(mprisToastRoot.length) : "--:--"
              }
            }
          }
        }
      }
    }
  }

  component MediaButton: Item {
    id: mediaButton

    property string glyph: ""

    signal clicked

    implicitHeight: 22
    implicitWidth: 22
    opacity: enabled ? 1 : 0.35

    HoverHandler {
      id: mediaHover
    }

    TapHandler {
      onTapped: mediaButton.clicked()
    }

    StyledText {
      anchors.fill: parent
      color: mediaHover.hovered ? Colors.lavender : Colors.text
      fontSize: 13
      horizontalAlignment: Qt.AlignHCenter
      propo: true
      text: mediaButton.glyph
      verticalAlignment: Qt.AlignVCenter
    }
  }
}
