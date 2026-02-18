# EasyLoadModules Spoon

**Goal**: A dynamic "Plugin Hub" for small automation scripts (Modules).

## Functionality

- **Scans** `modulespoon/` for `.lua` files.
- **Registers** them automatically.
- **Displays** them in a unified Menu (via `WindowGenerator`).

See [Modules Catalog](../../modulespoon/README-modules.md) for available modules.

## Usage

Trigger the menu (Default: `Option + Q`):

```lua
local WindowGenerator = require("common.window_generator")
  hs.hotkey.bind({ "alt" }, "q", function()
  WindowGenerator:show()
end)
```

## ⚙️ Custom Configuration

Modules are configured via a central JSON file located at \"Spoons/_conf_spoons/EasyLoadModulesSettings.json\".

- **`menu_order` (EasyLoadModules config)**: Defines the order modules appear in the menu. Unlisted modules appear alphabetically at the end.
- **`quickchar` (module example)**: Customizes the list of characters/text snippets available in the QuickChar module for rapid copying.


Example EasyLoadModulesSettings.json:

```json
{
    "menu_order": [
        "quickchar",
        "create file",
    ],"quickchar": [
        {
            "char": "{.}",
            "label": "Open/Closed bracket"
        },
        {
            "char": "[.]",
            "label": "Open/Closed square bracket"
        },
    ]
}
```