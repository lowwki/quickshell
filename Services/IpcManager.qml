pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import Quickshell.Wayland

Singleton {
  id: root

  property var focusState: WlrKeyboardFocus.None
 // property bool launcherOpen: false
  property bool logoutMenuOpen: false
  property bool tabletMode: false

  signal closeLogoutMenu
  signal enableTabletMode
  signal logoutMenu
  signal normalMode
 // signal toggleLauncher

  onCloseLogoutMenu: {
	root.focusState = WlrKeyboardFocus.None;
	root.logoutMenuOpen = false;
  }
	//  onToggleLauncher: {
	// root.launcherOpen = root.launcherOpen == true ? false : true;
	//  }

  IpcHandler {
	function disableTabletMode(): void {
	  root.normalMode();
	  root.tabletMode = false;
	}

	function enableTabletMode(): void {
	  root.enableTabletMode();
	  root.tabletMode = true;
	}

	function openLogoutMenu(): void {
	  root.logoutMenu();
	  root.focusState = WlrKeyboardFocus.Exclusive;
	  root.logoutMenuOpen = true;
	}

	target: "root"
  }
}
