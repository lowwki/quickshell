pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  id: root

  property MprisPlayer defaultPlayer: Mpris.players.values[0] || null

  function getPlaying() {
    return !!defaultPlayer && defaultPlayer.playbackState == MprisPlaybackState.Playing;
  }

  function prev() {
    if (!defaultPlayer)
      return;
    defaultPlayer.previous();
  }

  function skip() {
    if (!defaultPlayer)
      return;
    defaultPlayer.next();
  }

  function togglePlaying() {
    if (!defaultPlayer)
      return;
    defaultPlayer.togglePlaying();
  }
}
