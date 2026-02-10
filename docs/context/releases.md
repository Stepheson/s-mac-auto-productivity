# Release Notes - Refactor & Features Update

This release focuses on improving code maintainability (SOLID principles), standardizing naming conventions (snake_case), resolving critical bugs in hotkey handling, and introducing a new utility module.

## 🚀 New Features

- **Unhide App Module (`Spoons/EasyLoadModules.spoon/modules/unhide_app.lua`)**:
  - Lists hidden or minimized applications.
  - New icon support (`unhide_app.png`).
  - Filters out system processes (Listing only apps with `kind == 1`).
  - Provides menu actions to verify state (`[Hid]` / `[Min]`) and restore visibility.

## 🛠️ Refactoring & Architecture

- **Clean Architecture & SOLID Principles**:
  - **Single Responsibility Principle (SRP)**:
    - Created `common/file_manager.lua`: Centralized all low-level file I/O operations (read, write, check existence, mkdir).
    - Refactored `common/storage_manager.lua`: Now delegates I/O to `file_manager`, focusing only on serialization logic.
    - Refactored `common/config_parser.lua`: Now delegates I/O to `file_manager`, focusing only on JSON parsing logic.
  - **Dependency Inversion**: Modules now depend on the abstraction (`file_manager`) rather than direct `io.open` calls.

- **Configuration Centralization**:
  - Moved all Spoon-specific configuration files to `Spoons/_conf_spoons/`.
  - Updated paths in `EasyLoadModules.spoon` and `MonitorWindowApp.spoon` to reference this new location.

- **Standardization (Snake Case)**:
  - Renamed common modules to follow Lua conventions:
    - `WindowGenerator.lua` -> `window_generator.lua`
    - `managerMonitorsMac.lua` -> `manager_monitors_mac.lua`
    - `SideHotkey.lua` -> `side_hotkey.lua`
    - `autoReload.lua` -> `auto_reload.lua`
    - `configParser.lua` -> `config_parser.lua`
    - `finderUtils.lua` -> `finder_utils.lua`
    - `storageManager.lua` -> `storage_manager.lua`
    - `systemUtils.lua` -> `system_utils.lua`

## 🐛 Bug Fixes

- **Critical Init Error**:
  - Fixed `init.lua:80: attempt to index a nil value (field 'hotkey')` by explicitly requiring `hs.hotkey` before use. This resolved a loading race condition.

- **Hotkey Check Conflict**:
  - Fixed incorrect triggering of hotkeys in `common/side_hotkey.lua`.
  - Implemented **Strict Modifier Matching**: `LeftAlt+Shift+1` no longer triggers `LeftAlt+1` by verifying that _only_ the requested modifiers are pressed.

- **Dead Code Removal**:
  - Removed unused variables (e.g., `modState` in `side_hotkey.lua`).
  - Removed commented-out legacy code in `init.lua`, `window_generator.lua`, and `EasyLoadModules.spoon/init.lua`.

## 🧹 Code Cleanup

- Comprehensive scan of all `.lua` files to remove unused imports and legacy comments.
- Simplified `window_generator.lua` logic for screen ratio variables.

## 📚 Feature Documentation

### Common Modules (`common/`)

- **`auto_reload.lua`**: Automatically watches for configuration file changes (`.lua`, `.json`) and reloads Hammerspoon to apply updates immediately, excluding storage files to prevent loops.
- **`config_parser.lua`**: Specialized in parsing JSON configuration files. It abstracts the error handling for JSON decoding and delegates file reading to `file_manager`, ensuring a separation of concerns.
- **`file_manager.lua`**: Strictly handles low-level file I/O operations (read, write, check existence, create directories). It acts as the single source of truth for file access, adhering to SRP.
- **`finder_utils.lua`**: Provides utilities for interacting with the MacOS Finder, such as retrieving the POSIX path of the currently open implementation window or the Desktop.
- **`manager_monitors_mac.lua`**: Handles all screen-related logic, including identifying connected monitors, calculating centered window coordinates based on screen aspect ratios (portrait/landscape), and managing window focus.
- **`side_hotkey.lua`**: Advanced hotkey manager that implements "Strict Modifier Matching". It prevents conflicts between similar hotkeys (e.g., distinguishing `Alt+1` from `Alt+Shift+1`) by ensuring no extra modifiers are pressed.
- **`storage_manager.lua`**: Manages the persistence of Spoon state. It provides a simple API (`save`/`load`) for Spoons to store data in JSON format, abstracting the serialization details and delegating I/O to `file_manager`.
- **`system_utils.lua`**: Contains general system utilities, such as a function to force-kill and restart applications (useful for restarting Finder/Dock).
- **`window_generator.lua`**: Centralized hub for generating interactive "Chooser" windows (menus). It allows Spoons to register their commands and presents them in a unified UI, supporting nested menus and breadcrumb navigation.

### Spoons (`Spoons/`)

- **`AppCycler.spoon`**: Allows cycling through the open windows of the currently focused application, improving window management efficiency.
- **`AutomationControl.spoon`**: Master switch for the automation system. It can enable or disable the processing of other Spoons and hotkeys, allowing for a "maintenance mode" or temporary suspension of automations.
- **`MonitorWindowApp.spoon`**: Manages window positions, allowing users to move valid windows to specific monitors and predefined zones (e.g., "Left Monitor", "Center").
- **`EasyLoadModules.spoon`**: A dynamic loader that facilitates the creation and management of "Modules".
  - **Modules vs. Spoons**:
    - **Spoons** are full-fledged Hammerspoon plugins with a specific directory structure (`init.lua`, metadata, documentation), designed for complex, distributable features.
    - **Modules** (managed by `EasyLoadModules`) are lightweight, single-file Lua scripts designed for simple, specific tasks (like toggling a setting or running a quick command). They have minimal overhead, are easier to write for small automations, and `EasyLoadModules` automatically aggregates them into a unified menu system without requiring complex registration for each one.
    - **Performance & Resource Management**:
      - **Spoons**: Typically instantiate separate objects/tables and metadata, consuming more memory per unit. They are loaded entirely on startup (unless lazy-loaded), potentially increasing initialization time.
      - **Modules**: Execute within the shared `EasyLoadModules` context or as simple function returns. They have negligible memory footprint (often just the function closure) and zero processing overhead when idle, making them ideal for high-quantity, low-complexity scripts.

### 🧬 Module Template

To create a new module, simply add a `.lua` file to `Spoons/EasyLoadModules.spoon/modules/`. Here is the basic structure:

```lua
local module = {}
module.name = "MyNewModule"           -- Unique ID
module.version = "1.0"
module.author = "Your Name"
module.description = "Brief description of what this module does."

-- Optional Dependencies
-- local systemUtils = require("common.system_utils")
-- local iconsManager = require("icons_manager")

-- Main Menu Generator
-- Returns a list of menu items for the main chooser
function module.getMenuItems(options)
    return {
        {
            text = "My Action Label",
            subText = "Description of action",
            -- image = iconsManager.iconMyIcon,
            action = function()
                module.myFunction()
            end
        }
    }
end

-- Helper Functions
function module.myFunction()
    hs.alert.show("Hello from MyNewModule!")
end

return module
```
