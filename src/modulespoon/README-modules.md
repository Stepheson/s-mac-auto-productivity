# Lightweight Modules

These modules are lightweight automation scripts loaded dynamically by `EasyLoadModules.spoon`. They are designed for quick, specific actions without the overhead of a full Spoon.

## 📑 Module Catalog

| Module          | Description                                                  | Trigger         | Config Param  |
| :-------------- | :----------------------------------------------------------- | :-------------- | :------------ |
| **Dock**        | Toggle Dock auto-hide on/off.                                | Menu / `toggle` |               |
| **Finder**      | Show/Hide hidden files in Finder (`Cmd+Shift+.`).            | Menu / `toggle` |               |
| **Screenshot**  | Change default screenshot format (PNG, JPG, PDF, GIF, etc.). | Menu / List     |               |
| **Unhide App**  | List and restore hidden/minimized apps.                      | Menu / List     |               |
| **Create File** | Quickly create a file in the current Finder folder.          | Menu            |               |
| **Quick Char**  | Insert special characters.                                   | Menu            | \"quickchar\" |

## 🛠️ How to Create a Module

1.  Create a new `.lua` file in `modulespoon/`.
2.  Return a table with `name`, `getMenuItems`, or simpler action logic.
3.  **Auto-Registration**: `EasyLoadModules` scans this directory on reload. No manual wiring needed.

### Example

```lua
local obj = {}
obj.name = "MyModule"

function obj:getMenuItems(config)
    return {
        {
            text = "Hello World",
            action = function() module.helloFunction() end
        }
    }
end

return obj


function module.helloFunction()
    hs.alert.show("Hello.")
    return
end
```
