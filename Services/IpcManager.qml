pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool tabletMode: false

  IpcHandler {
    function disableTabletMode(): void {
      root.tabletMode = false;
    }

    function enableTabletMode(): void {
      root.tabletMode = true;
    }

    target: "root"
  }
}
