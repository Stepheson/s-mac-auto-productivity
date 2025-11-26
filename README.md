# s-MAC-Auto-Productivity

A modular, robust, and clean automation suite for macOS using [Hammerspoon](https://www.hammerspoon.org/). Designed to enhance productivity with multi-monitor window management and intelligent app cycling.

## 🚀 Overview

This project provides a set of independent "Spoons" (modules) that work together to:

1.  **Manage Windows**: Instantly move windows to specific monitors and positions.
2.  **Cycle Apps**: Smart `Alt+Tab` replacement that cycles through windows on the _current_ monitor only.
3.  **Control Automation**: A master switch to pause/resume all hotkeys globally.

## 📦 Spoons

### 1. MonitorWindowApp.spoon

A powerful window manager that remembers exactly where your apps should be, adapting to your environment.

- **Smart Profiles (Monitor Count)**: It automatically detects how many monitors are connected (e.g., "1 Monitor", "2 Monitors", "3 Monitors") and saves a unique layout for each scenario.
  - _Example_: You can have a "Home Office" setup with 3 monitors where VSCode is on the left and Chrome on the right. When you travel and use only your MacBook (1 monitor), it switches to a "Travel" profile where everything is maximized on the single screen. When you return home, it remembers your 3-monitor layout instantly.
- **Auto-Positioning**: Automatically restores window positions and dimensions when you switch contexts.
- **Auto-Reload**: Configuration changes are applied instantly without restarting Hammerspoon.
- **Smart Garbage Collection**: Automatically cleans up settings for closed apps (respecting hidden Spaces) to keep your config clean.

### 2. AppCycler.spoon

An intelligent window switcher restricted to the current monitor. Prevents the chaos of jumping between screens.

- **Features**:
  - **Mode 0 (Default)**: Cycle all visible windows (Stable order: Name + ID).
  - **Mode 1**: Cycle unique applications (one window per app).
  - **Mode 2**: Cycle instances of the current app only.

### 3. AutomationControl.spoon (Manager Extension)

The manager. It handles the lifecycle of other Spoons and hotkeys.

- **Features**:
  - Centralized Start/Stop for all registered hotkeys.
  - Visual feedback (Alerts) when automation is paused/resumed.

---

## ⚙️ Configuration (`init.lua`)

The `init.lua` file is designed to be a clean entry point. It wires the Spoons and defines hotkeys.

### Basic Setup

```lua
-- Load Spoons
hs.loadSpoon("AutomationControl")
hs.loadSpoon("MonitorWindowApp")
hs.loadSpoon("AppCycler")

-- Define Hotkeys Table
local hotkeys = {}
```

### 1. Master Switch (Always Active)

These hotkeys are **NOT** added to the `hotkeys` table, so `AutomationControl` cannot disable them. They remain active even when automation is paused.

```lua
hs.hotkey.bind({"alt", "shift"}, "0", function()
    spoon.AutomationControl:stop()
end)

hs.hotkey.bind({"alt", "shift"}, "1", function()
    spoon.AutomationControl:start()
end)
```

### 2. Operational Hotkeys (Managed)

These are added to the `hotkeys` table. `AutomationControl` will enable/disable them as needed.

```lua
-- Move to Monitor 1
table.insert(hotkeys, hs.hotkey.bind({"alt"}, "1", function()
    spoon.MonitorWindowApp:moveToMonitor("dell_standard", true)
end))

-- Cycle Apps (Mode 0 = All Windows)
table.insert(hotkeys, hs.hotkey.bind({"alt"}, "tab", function()
    spoon.AppCycler:cycle(0)
end))
```

### 3. Wiring AutomationControl

Finally, register the hotkeys and start the system.

```lua
if spoon.AutomationControl then
    -- Register Spoons for status updates
    spoon.AutomationControl:registerSpoon(spoon.MonitorWindowApp)
    spoon.AutomationControl:registerSpoon(spoon.AppCycler)

    -- Register Hotkeys for management
    spoon.AutomationControl:registerHotkeys(hotkeys)

    -- Start
    spoon.AutomationControl:start()
end
```

## 🛠️ Debugging

- **List Monitors**: `Alt + Shift + M` (Prints monitor names/IDs to Console).
- **Console**: Check the Hammerspoon Console for logs if something isn't working.

## 📂 Project Structure

- `init.lua`: Main configuration.
- `Spoons/`: Individual modules.
- `common/`: Shared utilities (`managerMonitorsMac`, `storageManager`, `autoReload`).
- `storage/`: JSON files where window positions are saved.
