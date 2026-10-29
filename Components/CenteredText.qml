import QtQuick

StyledText {
  property real yOffset: 0

  anchors.horizontalCenter: parent.horizontalCenter
  anchors.verticalCenter: parent.verticalCenter
  anchors.verticalCenterOffset: yOffset
}
