pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Defaults, used until config.lua loads (or if it has errors)
    property color surface: "#e611131b"
    property color surfaceAlt: "#e61b1c29"
    property color border: "#554b526a"
    property color text: "#e5d9f5"
    property color textDim: "#a5a0b8"
    property color accent: "#a88bc9"
    property int radius: 24

    readonly property var colorKeys: ["surface", "surfaceAlt", "border", "text", "textDim", "accent"]
    readonly property string configPath: Quickshell.shellPath("../config/config.lua")

    // 1) config.lua: manual theme values, then ask for the wallpaper palette if enabled
    function apply(json) {
        if (json.trim() === "") return;
        try {
            const cfg = JSON.parse(json);
            const t = cfg.theme || {};
            for (const k of colorKeys.concat(["radius"])) {
                if (t[k] !== undefined) root[k] = t[k];
            }
            const w = cfg.wallpaper || {};
            if (w.dynamic && w.path) {
                palette.command = ["lua", Quickshell.shellPath("../scripts/palette.lua"), w.path];
                palette.running = true;
            }
        } catch (e) {
            console.warn("Sigil: bad config output:", e);
        }
    }

    // 2) wallpaper palette: overrides the colors (not the radius)
    function applyPalette(json) {
        if (json.trim() === "") return; // palette script failed; its error is printed in the terminal
        try {
            const p = JSON.parse(json);
            for (const k of colorKeys) {
                if (p[k] !== undefined) root[k] = p[k];
            }
        } catch (e) {
            console.warn("Sigil: bad palette output:", e);
        }
    }

    Process {
        id: loader
        running: true
        command: ["lua", Quickshell.shellPath("../scripts/load-config.lua"), root.configPath]
        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }
    }

    Process {
        id: palette
        stdout: StdioCollector {
            onStreamFinished: root.applyPalette(text)
        }
    }

    FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: loader.running = true
    }
}
