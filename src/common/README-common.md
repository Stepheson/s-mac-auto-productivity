# Common Utilities

**Path**: `src/common/`

Shared libraries used by Spoons and Modules. These abstractions ensure consistent behavior across the automation suite.

## 🧰 Utilities List

| File                       | Purpose                                                                                 |
| :------------------------- | :-------------------------------------------------------------------------------------- |
| `window_generator.lua`     | **UI Hub**. Creates the searchable menus (Choosers) used by EasyLoadModules and others. |
| `side_hotkey.lua`          | **Input**. Distinguishes between Left/Right modifiers (e.g., LeftAlt vs RightAlt).      |
| `manager_monitors_mac.lua` | **Display**. Logic for calculating window positions and monitor geometry.               |
| `config_parser.lua`        | **Data**. robust JSON parsing for configuration files.                                  |
| `file_manager.lua`         | **I/O**. Safe file reading/writing operations.                                          |
| `storage_manager.lua`      | **Persistence**. State saving/loading (e.g., window positions).                         |
| `finder_utils.lua`         | **Finder**. Helpers for getting current Finder selection/path.                          |
| `system_utils.lua`         | **OS**. General system command helpers.                                                 |
| `auto_reload.lua`          | **Dev**. Auto-reloads Hammerspoon when files change.                                    |
