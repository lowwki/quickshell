import QtQuick
import "../Color.js" as Colors

Text {
  id: root

  property double fontSize: 11
  property double fontWeight: 7
  property bool propo: false

  color: Colors.base
  elide: Text.ElideRight

  font {
    family: root.propo ? "GeistMono Nerd Font Propo" : "GeistMono Nerd Font"
    pointSize: root.fontSize
    weight: root.fontWeight * 100
  }
}
