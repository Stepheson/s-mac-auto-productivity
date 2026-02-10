<p alingn="right"><code>Language:</code>
    <a href="README-pt.md"><img src="https://hatscripts.github.io/circle-flags/flags/br.svg" width="20" alt="Br" valign="middle"></a>
</p>

# s-MAC-Auto-Productivity (v2.0)

A modular, robust, and clean automation suite for macOS using [Hammerspoon](https://www.hammerspoon.org/).

> **Compatibility**: Tested on macOS **Sequoia** and **Tahoe**.

## 🚀 Overview

This project is built around independent "Spoons" (modules) tailored for this project, which can be easily expanded for future Spoons or existing ones. It has been re-architected in v2.0 to follow SOLID principles and Clean Architecture.

- **Independent Management**: Manage Spoons independently, making it easier to work with diverse modules with organized shortcuts.
- **Efficient Resource Usage**: New "EasyLoadModules" system for lightweight automations.
- **Agile Productivity**: Window management, App Cycling, and Quick System Toggles.

## 📑 Table of Contents

**🥄 Spoons (Action Modules)**

- [MonitorWindowApp.spoon](#-monitorwindowappspoon)
- [AppCycler.spoon](#-appcyclerspoon)
- [EasyLoadModules.spoon](#-easyloadmodulesspoon)
- [AutomationControl.spoon](#-automationcontrolspoon)

**🗜️ Common Resources (Management Tools)**

- [Advanced: Left vs Right Modifiers (SideHotkey)](#-advanced-left-vs-right-modifiers-sidehotkey)
- [Window Generator](#-window-generator)

---

---

## 🥄 SPOONS LIST

### 🎯 `MonitorWindowApp.spoon`

**Goal**: Quickly move windows between monitors installed on the Mac via keyboard shortcuts. When moving to a monitor, the window is identified and adjusted to the pre-configured dimension for apps on that monitor.

Positions are saved in a way that allows layout recovery if windows move out of place. Positions are saved by **monitor count groups**.

#### Configuration

1.  **Define Window Dimensions**:
    Edit the `Spoons/_conf_spoons/MonitorWindowAppSettings.json` file.
    - `monitorName`: Name as recognized by macOS.
    - `margins`: `left`, `right`, `top`, `bottom`.

    ```json
    [
      {
        "positionID": "monitor_MX279_margin_spaceleft_top",
        "monitorName": "MX279",
        "margins": { "left": 0.025, "top": 0.23 }
      }
    ]
    ```

---

### 🎯 `AppCycler.spoon`

**Goal**: An intelligent window switcher restricted to the **current monitor**. Avoids the chaos of jumping between screens.

- **Mode 0 (Default)**: Cycles all windows.
- **Mode 1**: Cycles windows only between different apps.
- **Mode 2**: Cycles instances only between instances of the same app.

#### Usage

```lua
-- Cycle windows on current monitor (Alt + Tab)
table.insert(hotkeys, hs.hotkey.bind({ "alt" }, "tab", function()
    spoon.AppCycler:cycle(0)
end))
```

---

### 🎯 `EasyLoadModules.spoon` (New in v2.0)

**Goal**: A dynamic "Plugin Hub" for small automation scripts (Modules). Replaces the old `SpeedMacosCustomConfigs`.

**Modules**:

1.  **Finder**: Show/Hide hidden files (`cmd+shift+.`).
2.  **Screenshot**: Change capture format (PNG, JPG, HEIC, PDF, GIF, TIFF).
3.  **Dock**: Toggle Dock auto-hide.
4.  **Unhide App**: List and restore hidden/minimized apps (ignoring system processes).

#### Usage

Trigger the menu with a hotkey (Default: `Alt + Q` to open WindowGenerator menu):

```lua
local WindowGenerator = require("common.window_generator")
SideHotkey.bind({ "leftAlt" }, "q", function()
  WindowGenerator:show()
end)
```

**Technical Difference**: Modules are lightweight scripts executed within a shared context, consuming negligible memory compared to full Spoons.

---

### 🎯 `AutomationControl.spoon`

**Goal**: The central manager. It controls the lifecycle (Start/Stop) of other Spoons and shortcuts.

- **Visual Feedback**: Shows alerts when Paused (🔴) or Resumed (🟢).

---

## 🗜️ Common Resources

### 🎯 `Advanced: Left vs Right Modifiers (side_hotkey)`

This is an extension belonging to `common/side_hotkey.lua`, distinguishing between Left and Right modifier keys.
Now supports **Strict Modifier Matching** to prevent conflicts (e.g., `Alt+1` won't trigger if `Alt+Shift+1` is pressed).

```lua
local SideHotkey = require("common.side_hotkey")
-- Triggers only with Left Alt
SideHotkey.bind({"leftAlt"}, "1", function() ... end)
```

### 🎯 `Window Generator (window_generator)`

Centralized hub for generating interactive "Chooser" windows (menus). Allows uniform UI for all Spoons and Modules.

---

## 📂 Project Structure (v2.0)

```
├── init.lua                        # Entry point
├── common/                         # Core Utilities
│   ├── side_hotkey.lua             # Hotkey Manager
│   ├── window_generator.lua        # UI Manager
│   ├── manager_monitors_mac.lua    # Screen Logic
│   ├── file_manager.lua            # I/O Abstraction
│   ├── config_parser.lua           # JSON Parsing
│   └── ...
├── Spoons/                         # Independent Modules
│   ├── _conf_spoons/               # Configuration JSONs
│   ├── MonitorWindowApp.spoon
│   ├── AppCycler.spoon
│   ├── AutomationControl.spoon
│   └── EasyLoadModules.spoon       # Module Loader
│       └── modules/                # Lightweight Scripts
│           ├── dock.lua
│           ├── finder.lua
│           ├── screenshot.lua
│           └── unhide_app.lua
└── releases.md                     # Changelog
```

## 🛠️ Debugging

- **List Monitors**: `Right Alt + Right Shift + M`.
- **Console**: Check Hammerspoon Console.

---

> [!NOTE]
> The "Alt" naming keys are the same as the Option keys on a Mac.
