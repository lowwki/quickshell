pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var workspaces: []

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

  // niri's event stream begins with the full current state and then sends deltas,
  // so the workspace list is kept up to date from the stream itself. This used to
  // spawn `niri msg --json workspaces` after every workspace event.
  function handleEvent(line) {
    // Window events are far more frequent; skip them before paying for JSON.parse
    if (!line.startsWith("{\"Workspace"))
      return;

    let event;
    try {
      event = JSON.parse(line);
    } catch (e) {
      return;
    }

    if (event.WorkspacesChanged) {
      workspaces = event.WorkspacesChanged.workspaces;
      return;
    }

    const activated = event.WorkspaceActivated;
    if (activated) {
      const target = workspaces.find(ws => ws.id === activated.id);
      if (!target)
        return;

      // One active workspace per output; one focused workspace overall (when `focused` is set)
      workspaces = workspaces.map(ws => Object.assign({}, ws, {
        is_active: ws.output === target.output ? ws.id === activated.id : ws.is_active,
        is_focused: activated.focused ? ws.id === activated.id : ws.is_focused
      }));
      return;
    }

    const windowChanged = event.WorkspaceActiveWindowChanged;
    if (windowChanged) {
      workspaces = workspaces.map(ws => ws.id === windowChanged.workspace_id
        ? Object.assign({}, ws, { active_window_id: windowChanged.active_window_id })
        : ws);
    }
  }

  Process {
    running: true
    command: ["niri", "msg", "--json", "event-stream"]

    stdout: SplitParser {
      onRead: line => root.handleEvent(line)
    }
  }
}
