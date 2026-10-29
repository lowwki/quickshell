pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

  signal newNotification(notification: Notification)

  NotificationServer {
    actionsSupported: true
    bodyMarkupSupported: true
    bodySupported: true
    imageSupported: true

    onNotification: notification => {
      notification.tracked = true;
      root.newNotification(notification);
    }
  }
}
