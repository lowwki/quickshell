pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  function _forOutput(outputName) {
    return NiriService.workspaces
      .filter(ws => ws.output === outputName)
      .sort((a, b) => a.idx - b.idx);
  }

  function _visibleForOutput(outputName) {
    return _forOutput(outputName).filter(ws =>
      ws.is_active || ws.name !== null || (ws.active_window_id !== null && ws.active_window_id !== undefined));
  }

  function getWorkspacesForMonitor(monitor) {
    if (!monitor)
      return [];
    return _visibleForOutput(monitor.name);
  }

  function getWorkspaceStateIndex(workspace) {
    if (workspace.is_focused)
      return 0;
    if (workspace.is_active)
      return 1;
    return 2;
  }

  function activateWorkspace(workspace) {
    if (!workspace)
      return;
    Quickshell.execDetached(["sh", "-c",
      "niri msg action focus-monitor \"$1\" && niri msg action focus-workspace \"$2\"",
      "sh", workspace.output, String(workspace.idx)]);
  }

  function focusNext() {
    Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"]);
  }

  function focusPrevious() {
    Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"]);
  }
}
