pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


Singleton {
  id: root

  property var workspaces: []
  property string _lastJson: ""
  property bool _pending: false

  readonly property string focusedOutput: {
    for (const ws of workspaces) {
      if (ws.is_focused)
        return ws.output;
    }
    return "";
  }

  function isFocused(screen) {
    return !!screen && screen.name === focusedOutput;
  }

  function refresh() {
    if (query.running)
      _pending = true;
    else
      query.running = true;
  }

  Process {
    id: query

    command: ["niri", "msg", "--json", "workspaces"]

    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text !== root._lastJson) {
          try {
            root.workspaces = JSON.parse(this.text);
            root._lastJson = this.text;
          } catch (e) {}
        }
        if (root._pending) {
          root._pending = false;
          query.running = true;
        }
      }
    }
  }

  Process {
    running: true
    command: ["niri", "msg", "--json", "event-stream"]

    stdout: SplitParser {
      onRead: line => {
        if (line.startsWith("{\"Workspace"))
          root.refresh();
      }
    }
  }

  Component.onCompleted: refresh()
}
