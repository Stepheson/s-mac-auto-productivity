# s-MAC-Auto-Productivity (v2.0 Alfa)

<!-- <a href="README-pt.md"><img src="https://hatscripts.github.io/circle-flags/flags/br.svg" width="20" alt="Br"></a> -->
<img align="right" src="https://img.shields.io/badge/Language-Lua-gold.svg" alt="Lua">
<img align="right" src="https://img.shields.io/badge/Platform-macOS-lightgrey.svg" alt="macOS">

A modular, robust, and clean automation suite for macOS using [Hammerspoon](https://www.hammerspoon.org/).

> **Compatibility**: Tested on macOS **Sequoia** and **Tahoe**.

## 🚀 Overview

This project is built around independent "Spoons" (modules) tailored for productivity, following SOLID principles and Clean Architecture.

- **Independent Management**: Manage Spoons independently with organized shortcuts.
- **Efficient Resource Usage**: New "EasyLoadModules" system for lightweight automations.
- **Agile Productivity**: Window management, App Cycling, and Quick System Toggles.

## ⌨️ Current Preconfigured Spoons and Shortcuts

```
Spoons --> Monitor[MonitorWindowApp]
Spoons --> Cycler[AppCycler]
Spoons --> Control[AutomationControl]
Spoons --> EasyLoad[EasyLoadModules]
```

| Hotkey                          | Action                                 | Scope              |
| :------------------------------ | :------------------------------------- | :----------------- |
| `LeftAlt` + `Tab`               | Cycle Windows (Current Monitor)        | AppCycler          |
| `LeftAlt` + `Q`                 | Open Modules Menu (Dock, Finder, etc.) | EasyLoadModules    |
| `LeftAlt` + `1/2/3`             | Move Window to Monitor 1/2/3           | MonitorWindowApp   |
| `RightAlt` + `RightShift` + `0` | **Stop/Pause** Automation              | AutomationControl  |
| `RightAlt` + `RightShift` + `1` | **Start/Resume** Automation            | AutomationControl  |
| `RightAlt` + `RightShift` + `m` | List Connected Monitors - Debug        | managerMonitorsMac |

### Components

- **[Spoons](Spoons/)**: Full-featured Hammerspoon modules (Window management, App cycling).
- **[Common](common/README-common.md)**: Shared libraries for window generation, file I/O, and config parsing.
- **[Modules](modulespoon/README-modules.md)**: Lightweight scripts managed by `EasyLoadModules` (System toggles, specific actions).

## 🏗️ Architecture

The codebase.

```
├── init.lua                   # Entry point (main config)
├── Spoons/                    # Robust Automation Modules
│   ├── storage_configs/       # Dynamic state storage (JSON)
│   └── _conf_spoons/          # Spoon configuration files (JSON)
├── modulespoon/               # Lightweight Action Scripts
└── common/                    # Shared Utilities & Resources
```

## 🤝 Contribution

To add a new feature:

1.  **Lightweight**: Add a single `.lua` file to `modulespoon/`. It auto-registers with `EasyLoadModules`.
2.  **Complex**: Create a new Spoon in `Spoons/`.

See specific component READMEs for details.
