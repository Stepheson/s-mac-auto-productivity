> > > SYSTEM MANUAL: HAMMERSPOON PRODUCTIVITY MANAGER
> > > VERSION: 1.1.0

[1] OS ENVIRONMENT
--- Compatibility: macOS (Target: Sequoia and Tahoe).
--- Interface Language: English (System paths and settings must be referenced in English, e.g., Settings > Privacy).
--- Core Dependency: Hammerspoon API (Latest stable).

[2] TECHNICAL ARCHITECTURE AND RESOURCES

**_ Core Structure _**
The project follows a Modular Architecture with strict adherence to SOLID principles (SRP and Separation of Concerns).

--- Orchestrator (init.lua): - Role: Configuration entry point. - Responsibility: Wires Spoons, defines hotkeys, and injects dependencies. Contains NO business logic. - Pattern: Dependency Injection.

--- Spoons (Actions): - Independent, self-contained modules located in /Spoons. - MonitorWindowApp: Domain logic for window management and persistence. Maps 'positionID' to hardware Monitor Names. - AppCycler: Domain logic for window cycling and filtering. - AutomationControl: Infrastructure logic for lifecycle management (Start/Stop). - SpeedMacosCustomConfigs: Quick system toggles (Finder, Dock, Screenshot).

--- Common (Management): - Shared utilities located in /common. - managerMonitorsMac.lua: Abstraction layer for hs.window/hs.screen. Handles sorting, filtering, and detection. - storageManager.lua: Generic JSON I/O handler. - SideHotkey.lua: CRITICAL resource for modifier distinction. - autoReload.lua: Watcher for file changes to trigger reload.

**_ SideHotkey Resource _**
--- Location: common/SideHotkey.lua
--- Purpose: Critical resource that distinguishes between Left and Right modifier keys to prevent conflicts with native macOS shortcuts.
--- Mechanism: Uses hs.eventtap to track hardware keycodes.
Left Alt: 58 | Right Alt: 61
Left Cmd: 55 | Right Cmd: 54
Left Shift: 56 | Right Shift: 60
Left Ctrl: 59 | Right Ctrl: 62
--- Usage: Required for all custom automation bindings in init.lua.

**_ SpeedMacosCustomConfigs Implementation _**
--- Structure: init.lua loads sub-modules from /modules directory.
--- Mechanism: Dynamically builds a chooser menu based on loaded modules.
--- Modules:
finder.lua: Toggles "Show Hidden Files" (AppleShowAllFiles).
screenshot.lua: Sets capture format (PNG/JPG).
dock.lua: Toggles Dock autohide.

[3] CURRENT LOGIC STATE (ADR)

**_ Architecture Decision Records _**
--- Side-Specific Modifiers:
Decision: Use SideHotkey binding (e.g., Left Alt) for automation.
Reason: Prevents "shadowing" of system hotkeys, allowing co-existence. Users keep system defaults on one side (e.g., Right Alt) and automation on the other.

--- Compound Shortcuts:
Decision: Use multi-key bindings for critical controls (Right Alt + Right Shift).
Reason: Minimizes accidental triggers for system-level commands (e.g., Debugging, Start/Stop).

--- Dual-Language Documentation:
Decision: Maintain README.md (English) and README-pt.md (Portuguese).
Reason: Support broader audience while keeping English as the technical standard.

--- Garbage Collection (Conservative Strategy):
Decision: "Innocent until proven guilty" for window data.
Reason: macOS hides windows on other Spaces returning nil; data is only deleted if the specific App is terminated to prevent data loss.

--- Window Cycling (Stable Sort):
Decision: Sort windows by App Name + Window ID.
Reason: Ensures deterministic cycle order regardless of focus history or Z-order changes.

[4] MODULE AND SPOON RULES

**_ init.lua Standards _**
--- Wiring: init.lua must strictly use `SideHotkey.bind` for automation triggers where side distinction is required.
--- Registration: All Spoons must be registered via `spoon.AutomationControl:registerSpoon()` to ensure lifecycle management.
--- Hotkeys: Global hotkeys must be registered via `spoon.AutomationControl:registerHotkeys()` to support clean Start/Stop toggling.

**_ Menu Generation Rules _**
--- SpeedMacosCustomConfigs: `buildMenu()` must handle nil modules gracefully.
--- Execution: Use `hs.task` or `hs.execute` for system commands (defaults, killall).

**_ Module Details _**
--- common/managerMonitorsMac.lua: - Key Function: getVisibleWindowsOnScreen(screenId, mode). - Modes: 0 (All Windows Sorted), 1 (Unique Apps), 2 (Current App Instances).
--- Spoons/MonitorWindowApp.spoon: - Storage: Uses MonitorWindowAppSt.json. - Logic: Maps config 'positionID' to Hardware Monitor Name. - Validation: Checks connection before moving.
--- Spoons/AutomationControl.spoon: - State: isActive (boolean). - Null Object Safety: init.lua checks 'if spoon.AutomationControl' before use.

[5] BUSINESS RULES AND COMPATIBILITY

**_ Performance _**
--- Execution Flow: Optimized for minimal latency. Event taps (SideHotkey) must be efficient.
--- Compatibility: Features must be tested against macOS Sequoia and Tahoe.

**_ File Organization _**
--- Root: - init.lua (Entry Point) - MonitorWindowAppSettings.json (User Config)
--- .agent/rules: - System_Instruction.md (Technical Manual)
--- Spoons/: - AutomationControl.spoon/ (init.lua) - MonitorWindowApp.spoon/ (init.lua) - AppCycler.spoon/ (init.lua) - SpeedMacosCustomConfigs.spoon/ (init.lua, modules/)
--- common/: - SideHotkey.lua - managerMonitorsMac.lua - storageManager.lua - autoReload.lua - configParser.lua
--- storage/: - MonitorWindowAppSt.json (Persisted Runtime Data)

**_ Naming Conventions _**
--- Spoons: PascalCase (e.g., MonitorWindowApp.spoon).
--- Common Libs: camelCase (e.g., sideHotkey.lua, managerMonitorsMac.lua).
