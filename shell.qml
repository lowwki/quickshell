import QtQuick
import Quickshell
import "./Bar"

Scope {
  Bar {}

  // One launcher for the whole shell, not one per monitor
  Launcher {}
}
