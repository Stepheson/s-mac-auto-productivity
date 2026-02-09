<p alingn="right"><code>Language:</code>
    <a href="README-pt.md"><img src="https://hatscripts.github.io/circle-flags/flags/br.svg" width="20" alt="Br" valign="middle"></a>
</p>

# s-MAC-Auto-Productivity

A modular, robust, and clean automation suite for macOS using [Hammerspoon](https://www.hammerspoon.org/).

> **Compatibility**: Tested on macOS **Sequoia** and **Tahoe**.

## 🚀 Overview

This project is built around independent "Spoons" (modules) tailored for this project, which can be easily expanded for future Spoons or existing ones. It allows:

- **Independent Management**: Manage Spoons independently, making it easier to work with diverse modules with organized shortcuts.
- **Agile Productivity**: Current Spoons allow easy window swapping between monitors via shortcuts with pre-configured dimensions, and quick macOS system setting toggles. And more to be implemented.

## 📑 Table of Contents

**🥄 Spoons (Action Modules)**

- [MonitorWindowApp.spoon](#-monitorwindowappspoon)
- [AppCycler.spoon](#-appcyclerspoon)
- [SpeedMacosCustomConfigs.spoon](#-speedmacoscustomconfigsspoon)
- [AutomationControl.spoon](#-automationcontrolspoon)

**🗜️ Common Resources (Management Tools)**

- [Advanced: Left vs Right Modifiers (SideHotkey)](#-advanced-left-vs-right-modifiers-sidehotkey)

---

---

## 🥄 SPOONS LIST

### 🎯 `MonitorWindowApp.spoon`

**Goal**: Quickly move windows between monitors installed on the Mac via keyboard shortcuts. When moving to a monitor, the window is identified and adjusted to the pre-configured dimension for apps on that monitor. You can configure more than one shortcut for the same monitor.

Positions are saved in a way that allows layout recovery if windows move out of place (due to machine lock or monitor removal). Positions are saved by **monitor count groups** (e.g., a configuration for "1 monitor" and another for "2 monitors" are saved independently).

#### Configuration

1.  **Define Window Dimensions (`MonitorWindowAppSettings.json`)**:
    Create or edit the `MonitorWindowAppSettings.json` file in the root.
    - `monitorName`: Name as recognized by the macOS operating system. (Go to macOS Display settings or activate the project debug mode `Right Alt + Right Shift + m` and check the console).
    - `margins`: Supported margins: `left`, `right`, `top`, `bottom`.

    ```json
    [
      {
        "positionID": "monitor_MX279_margin_spaceleft_top",
        "monitorName": "MX279",
        "margins": { "left": 0.025, "top": 0.23 }
      },
      {
        "positionID": "builtin_standard",
        "monitorName": "Built-in Retina Display",
        "margins": { "left": 0.035 }
      }
    ]
    ```

2.  **Bind Hotkeys (`init.lua`)**:
    Bind a key to move the current window to the defined position.

    ```lua
    -- Move to "builtin_standard" position
    table.insert(hotkeys, hs.hotkey.bind({ "alt" }, "3", function()
      spoon.MonitorWindowApp:moveToMonitor("builtin_standard", true)
    end))
    ```

---

### 🎯 `AppCycler.spoon`

**Goal**: An intelligent window switcher restricted to the **current monitor**. Avoids the chaos of jumping between screens when you just want to switch context locally.

- **Mode 0 (Default)**: Cycles all windows even if there is more than one instance of the same app open in the window.
- **Mode 1**: Cycles windows only between different apps.
- **Mode 2**: Cycles instances only between instances of the same app, the current one on screen.

#### Usage

Use the function `spoon.AppCycler:cycle({Mode})` in your shortcut.

```lua
-- Cycle windows on current monitor (Alt + Tab)
table.insert(hotkeys, hs.hotkey.bind({ "alt" }, "tab", function()
    spoon.AppCycler:cycle(0)
end))
```

---

### 🎯 `SpeedMacosCustomConfigs.spoon`

**Goal**: A quick-access menu for useful macOS system settings.

This Spoon is divided into internal modules:

1.  **Finder**: Show or hide hidden files (same as macOS shortcut `cmd+shift+.`).
2.  **Screenshot**: Choose capture format (PNG, JPG).
3.  **Dock**: Enable/Disable Dock auto-hide.

#### Usage

Trigger the menu with a hotkey (Default: `Alt + 7`):

```lua
table.insert(hotkeys, hs.hotkey.bind({ "alt" }, "7", function()
  spoon.SpeedMacosCustomConfigs:showMenu()
end))
```

---

### 🎯 `AutomationControl.spoon`

**Goal**: The central manager. It controls the lifecycle (Start/Stop) of other Spoons and shortcuts. Useful for temporarily disabling all automation.

- **Visual Feedback**: Shows alerts when Paused (🔴) or Resumed (🟢).

#### Configuration

For the manager to work, you need to **register** the Spoons and the hotkeys table in `init.lua`.

**Pre-configured Shortcuts (Example):**

- Disable: `Right Alt` + `Right Shift` + `0`
- Enable: `Right Alt` + `Right Shift` + `1`

```lua
if spoon.AutomationControl then
    -- Register Spoons for control
    spoon.AutomationControl:registerSpoon(spoon.MonitorWindowApp)
    spoon.AutomationControl:registerSpoon(spoon.AppCycler)

    -- Register hotkeys table
    spoon.AutomationControl:registerHotkeys(hotkeys)

    -- Start system
    spoon.AutomationControl:start()
end
```

---

## 🗜️ Common Resources

### 🎯 `Advanced: Left vs Right Modifiers (`SideHotkey`)`

This is an extension belonging to `common/SideHotkey.lua` resources, to distinguish between Left and Right modifier keys (Alt/Option, Cmd, Shift).

This allows you to use the **Left Alt** key for your custom automations, keeping the **Right Alt** key free for standard macOS shortcuts (or vice-versa). If the shortcut does not use this feature, the predefined key will be triggered regardless of the keyboard side.

Supported modifiers: `leftAlt`, `rightAlt`, `leftCmd`, `rightCmd`, `leftShift`, `rightShift`, `leftCtrl`, `rightCtrl`.

#### Usage

**WITHOUT SideHotkey (Default Behavior):**
Any Alt key triggers the command.

```lua
hs.hotkey.bind({"alt"}, "1", function() ... end)
```

**WITH SideHotkey (Side Distinction):**
Only the LEFT Alt key triggers.

```lua
local SideHotkey = require("common.SideHotkey")

-- Triggers only with Left Alt
SideHotkey.bind({"leftAlt"}, "1", function() ... end)
```

> **TIP**: It is possible to use mixed shortcuts, some using `hs.hotkey` (both sides) and others using `SideHotkey` (specific side) in the same `init.lua` file.

---

---

## 📂 Project Structure

```
├── init.lua                   # Entry point (main config)
├── MonitorWindowAppSettings.json # User position config
├── common/                    # Common Resources
│   ├── SideHotkey.lua         # Left/Right key distinction
│   ├── managerMonitorsMac.lua # Monitor detection
│   └── ...
├── storage/                   # Configuration storage per Spoon
│   └── ...
└── Spoons/                    # Independent Modules (Actions)
    ├── MonitorWindowApp.spoon # Window Management
    ├── AppCycler.spoon        # App Switcher
    ├── AutomationControl.spoon# Lifecycle Manager
    └── SpeedMacosCustomConfigs.spoon # System Tools
        └── modules/           # (finder, screenshot, dock)
```

## 🛠️ Debugging

- **List Monitors**: `Right Alt + Right Shift + M` (Prints monitor names/IDs to Console).
- **Console**: Check the Hammerspoon Console if something isn't working.

---

> [!NOTE]
> The "Alt" naming keys are the same as the Option keys on a Mac.
