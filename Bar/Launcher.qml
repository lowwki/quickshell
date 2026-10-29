import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../Color.js" as Colors

Scope {
    id: root
    property bool open: false
    property string initial: ""
    property color accent: Colors.red  
    readonly property string home: Quickshell.env("HOME")
    property string emojiFile: Quickshell.env("EMOJI_FILE") || (home + "/.local/share/emoji-test.txt")
    property var emojis: []
    property bool emojiLoading: false
    property bool emojiTried: false

    property string terminal: Quickshell.env("TERMINAL_BIN") || "kitty"
    property string editor: Quickshell.env("EDITOR_BIN") || "nvim"

    // text files in nvim
    function openFile(path) {
    
        Quickshell.execDetached(["sh", "-c",
            'case "$(file -Lb --mime-type -- "$1")" in text/*|application/json|application/xml|application/javascript|application/x-shellscript|application/x-yaml|application/toml|application/x-ndjson|inode/x-empty) shift; exec "$@" ;; *) exec xdg-open "$1" ;; esac',
            "sh", path, terminal, editor, path])
        }

    // open / close
    function show(prefix) { root.initial = prefix; root.open = true }
    function close() { root.open = false; root.initial = "" }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.open ? root.close() : root.show("") }
        function apps(): void { root.show("") }
        function files(): void { root.show("f ") }
        function emoji(): void { root.show("e ") }
        function clipboard(): void { root.show("c ") }
    }

    // clipboard history
    Process {
        running: true
        command: ["sh", "-c", "pgrep -x wl-paste >/dev/null || exec wl-paste --watch cliphist store"]
    }

    // 
    readonly property var web: ({
        yt: { label: "YouTube", url: "https://www.youtube.com/results?search_query=" },
        g:  { label: "Google",  url: "https://www.google.com/search?q=" },
        gh: { label: "GitHub",  url: "https://github.com/search?q=" },
        ff: { label: "Firefox", firefox: true }
    })
    function webSearch(w, term) {
        if (w.firefox) Quickshell.execDetached(["firefox", "--search", term])
        else Quickshell.execDetached(["xdg-open", w.url + encodeURIComponent(term)])
    }

    //  system actions 
    // keep: true , run the action but dont close the launcher
    readonly property var actions: [
        { name: "logout",          keys: "exit niri",         cmd: ["niri", "msg", "action", "quit" ] },
        { name: "hibernate",       keys: "",                  cmd: ["systemctl", "hibernate"] },
        { name: "suspend",         keys: "sleep",             cmd: ["systemctl", "suspend"] },
        { name: "shutdown",        keys: "poweroff power off", cmd: ["poweroff"] },
        { name: "reboot",          keys: "restart",           cmd: ["reboot"] },
        { name: "volume up",       keys: "sound audio louder", keep: true, cmd: ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"] },
        { name: "volume down",     keys: "sound audio quieter", keep: true, cmd: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"] },
        { name: "mute",            keys: "volume toggle",     keep: true, cmd: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] },
        { name: "brightness up",   keys: "backlight screen",  keep: true, cmd: ["brightnessctl", "set", "5%+"] },
        { name: "brightness down", keys: "backlight screen",  keep: true, cmd: ["brightnessctl", "set", "5%-"] },
        { name: "bluetooth on",    keys: "",                  keep: true, cmd: ["bluetoothctl", "power", "on"] },
        { name: "bluetooth off",   keys: "",                  keep: true, cmd: ["bluetoothctl", "power", "off"] },
        { name: "night mode up",   keys: "nightlight blue light filter warmer more", keep: true, cmd: ["nightmode", "up"] },
        { name: "night mode down", keys: "nightlight blue light filter cooler less", keep: true, cmd: ["nightmode", "down"] },
        { name: "night mode",      keys: "nightlight blue light filter toggle",      keep: true, cmd: ["nightmode", "toggle"] },
        { name: "night mode off",  keys: "nightlight blue light filter",             keep: true, cmd: ["nightmode", "off"] },
        { name: "wifi",      keys: "wifitui internet",              keep: false, cmd: ["kitty", "-e", "wifitui"] },
        { name: "bluetooth", keys: "bt bluetui pairing devices",    keep: false, cmd: ["kitty", "-e", "bluetui"] }
    ]

    // emoji
    function loadEmoji() {
        if (emojiLoading || emojiTried) return
        emojiTried = true
        emojiLoading = true
        emojiProc.running = true
    }
    Process {
        id: emojiProc
        command: ["sh", "-c",
            'for f in "$1" /run/current-system/sw/share/unicode/emoji/emoji-test.txt /usr/share/unicode/emoji/emoji-test.txt /usr/share/unicode/emoji-test.txt; do [ -r "$f" ] && exec grep -F "; fully-qualified" "$f"; done',
            "sh", root.emojiFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const m = line.match(/# (\S+) E[\d.]+ (.+)$/)
                    if (m && m[2].indexOf("skin tone") < 0) out.push({ ch: m[1], name: m[2] })
                }
                root.emojiLoading = false
                if (out.length > 0) root.emojis = out
            }
        }
    }
    function typeText(t) {
        Quickshell.execDetached(["sh", "-c", 'wl-copy -- "$1"; sleep 0.3; wtype -- "$1"', "sh", t])
    }
    function pasteClip(id) {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy; sleep 0.3; wtype -M ctrl v -m ctrl', "sh", id])
    }

    // the launcher
    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "launcher"

            anchors.top: true
            margins.top: Math.round((screen ? screen.height : 1080) * 0.30)

            readonly property int rows: 10      // max visible results
            readonly property int rowH: 24
            implicitWidth: 600
            implicitHeight: Math.min(results.length, rows) * rowH + 60

            property var results: []
            property var clipItems: []
            property string mode: "apps"
            property string lastMode: ""

            function score(text, q) {
                text = (text || "").toLowerCase()
                if (text.startsWith(q)) return 3
                if (text.indexOf(q) >= 0) return 2
                return 0
            }

            function parse(raw) {
                if (raw.startsWith("f ")) return { mode: "files", q: raw.slice(2).trim() }
                if (raw.startsWith("e ")) return { mode: "emoji", q: raw.slice(2).trim() }
                if (raw.startsWith("c ")) return { mode: "clip",  q: raw.slice(2).trim() }
                return { mode: "apps", q: raw.trim() }
            }

            function appResults(p, q) {
                const out = []
                const sp = p.q.indexOf(" ")
                if (sp > 0) {
                    const w = root.web[p.q.slice(0, sp)]
                    const term = p.q.slice(sp + 1).trim()
                    if (w && term)
                        out.push({ s: 99, i: 0, name: w.label + ": " + term, sub: "",
                                   run: () => root.webSearch(w, term) })
                }
                const apps = DesktopEntries.applications.values
                for (let i = 0; i < apps.length; i++) {
                    const a = apps[i]
                    const s = Math.max(score(a.name, q), score(a.genericName, q) > 0 ? 1 : 0)
                    if (s > 0) out.push({ s: s, i: i, name: a.name, sub: a.comment || "",
                                          run: () => a.execute() })
                }
                if (q === "") return out
                for (let i = 0; i < root.actions.length; i++) {
                    const act = root.actions[i]
                    const s = Math.max(score(act.name, q), score(act.keys, q) > 0 ? 1 : 0)
                    if (s > 0) out.push({ s: s + 0.5, i: i, name: act.name, sub: "",
                                          keep: act.keep === true,
                                          run: () => Quickshell.execDetached(act.cmd) })
                }
                return out
            }

            function emojiResults(q) {
                if (root.emojis.length === 0) root.loadEmoji()
                const out = []
                for (let i = 0; i < root.emojis.length; i++) {
                    const e = root.emojis[i]
                    const s = q === "" ? 1 : score(e.name, q)
                    if (s > 0) out.push({ s: s, i: i, name: e.ch + "  " + e.name, sub: "",
                                          run: () => root.typeText(e.ch) })
                }
                return out
            }

            function clipResults(q) {
                if (lastMode !== "clip") { clipItems = []; clip.running = true }
                const out = []
                for (let i = 0; i < clipItems.length; i++) {
                    const c = clipItems[i]
                    const s = q === "" ? 1 : score(c.text, q)
                    if (s > 0) out.push({ s: s, i: i, name: c.text.replace(/\s+/g, " "), sub: "",
                                          run: () => root.pasteClip(c.id) })
                }
                return out
            }

            function update() {
                const p = parse(input.text)
                mode = p.mode

                if (p.mode === "files") {
                    if (lastMode !== "files") results = []
                    lastMode = p.mode
                    fileTimer.restart()
                    return
                }

                const q = p.q.toLowerCase()
                const out = p.mode === "apps" ? appResults(p, q)
                          : p.mode === "emoji" ? emojiResults(q)
                          : clipResults(q)

                const byName = p.mode === "apps"
                out.sort((a, b) => b.s - a.s || (byName ? a.name.localeCompare(b.name) : a.i - b.i))
                results = out.slice(0, 50)
                list.currentIndex = 0
                lastMode = p.mode
            }

            function runCurrent() {
                const it = results[list.currentIndex]
                if (!it) return
                it.run()
                if (it.keep) input.forceActiveFocus()
                else root.close()
            }

            Connections {
                target: root
                function onEmojisChanged() { win.update() }
                function onInitialChanged() { input.text = root.initial }
            }

            // files fd and fzf uses
            Timer {
                id: fileTimer
                interval: 120
                onTriggered: {
                    const q = win.parse(input.text).q
                    fd.running = false
                    if (q === "") { win.results = []; return }
                    fd.command = ["sh", "-c",
                        'fd --type f --hidden --exclude .git --exclude node_modules --exclude .cache --base-directory "$1" . | fzf --filter "$2" | head -n 50',
                        "sh", root.home, q]
                    fd.running = true
                }
            }
            Process {
                id: fd
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (win.mode !== "files") return
                        win.results = text.trim().split("\n").filter(l => l).map((rel, i) => {
                            const p = root.home + "/" + rel
                            return {
                                s: 1, i: i, name: rel.split("/").pop(), sub: "~/" + rel,
                                run: () => root.openFile(p)
                            }
                        })
                        list.currentIndex = 0
                    }
                }
            }

            // clipboard history cliphist
            Process {
                id: clip
                command: ["cliphist", "list"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        win.clipItems = text.split("\n").map(l => {
                            const t = l.indexOf("\t")
                            return t > 0 ? { id: l.slice(0, t), text: l.slice(t + 1) } : null
                        }).filter(x => x)
                        win.update()
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: Colors.base
                border.width: 1
                border.color: Colors.surface1

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    //  typing bar (top, fixed pos)
                    Item {
                        width: parent.width
                        height: 20
                        Text {
                            id: prompt
                            anchors.verticalCenter: parent.verticalCenter
                            text: "> "
                            color: root.accent
                            font.family: "monospace"
                            font.pixelSize: 15
                        }
                        TextInput {
                            id: input
                            anchors { left: prompt.right; leftMargin: 10; right: parent.right
                                      verticalCenter: parent.verticalCenter }
                            color: Colors.text
                            font.family: "monospace"
                            font.pixelSize: 15
                            focus: true
                            onTextChanged: win.update()
                            Keys.onEscapePressed: root.close()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onReturnPressed: win.runCurrent()
                            Keys.onEnterPressed: win.runCurrent()
                            Keys.onPressed: event => {
                                if (event.modifiers & Qt.ControlModifier) {
                                    if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                                        list.decrementCurrentIndex(); event.accepted = true
                                    } else if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                                        list.incrementCurrentIndex(); event.accepted = true
                                    }
                                }
                            }
                            Component.onCompleted: {
                                text = root.initial
                                forceActiveFocus()
                                win.update()
                            }
                        }
                    }

                    //  status line
                    Row {
                        width: parent.width
                        height: 18
                        spacing: 10
                        Text {
                            id: cnt
                            anchors.verticalCenter: parent.verticalCenter
                            text: (win.results.length ? list.currentIndex + 1 : 0) + "/" + win.results.length
                            color: Colors.overlay1
                            font.family: "monospace"
                            font.pixelSize: 12
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 1
                            width: parent.width - cnt.implicitWidth - lbl.implicitWidth - 20
                            color: Colors.surface2
                        }
                        Text {
                            id: lbl
                            anchors.verticalCenter: parent.verticalCenter
                            text: win.mode
                            color: Colors.overlay1
                            font.family: "monospace"
                            font.pixelSize: 12
                        }
                    }

                    //  results (below, grows down)
                    ListView {
                        id: list
                        width: parent.width
                        height: Math.min(win.results.length, win.rows) * win.rowH
                        model: win.results
                        clip: true
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool sel: ListView.isCurrentItem
                            width: list.width
                            height: win.rowH
                            color: sel ? Colors.surface0 : "transparent"

                            Rectangle {
                                visible: parent.sel
                                width: 3
                                height: parent.height
                                color: root.accent
                            }
                            Text {
                                id: nm
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, parent.width * 0.65)
                                text: modelData.name
                                elide: Text.ElideRight
                                color: parent.sel ? Colors.text : Colors.subtext0
                                font.family: "monospace"
                                font.pixelSize: 14
                            }
                            Text {
                                anchors { left: nm.right; leftMargin: 12; right: parent.right
                                          rightMargin: 10; verticalCenter: parent.verticalCenter }
                                text: modelData.sub
                                elide: Text.ElideMiddle
                                color: Colors.overlay1
                                font.family: "monospace"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { list.currentIndex = index; win.runCurrent() }
                            }
                        }
                    }
                }
            }
        }
    }
}
