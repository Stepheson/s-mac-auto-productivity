# MonitorWindowApp Spoon

**Goal**: Quickly move windows between monitors. When moving to a monitor, the window is identified and adjusted to the pre-configured dimension for apps on that monitor.

## Configuration

Defines window dimensions/margins per monitor in `Spoons/_conf_spoons/MonitorWindowAppSettings.json`.


```json
[
  {
    "positionID": "builtin_standard_margin_spaceleft",
    "monitorName": "Built-in Retina Display", 
    "margins": { "left": 0.025, "top": 0.23, "right": 0, "bottom": 0.02 }
  }
]
```

> **Note**: 
> - `positionID` must be exactly the name of the position.
> - `monitorName` must be exactly the name of the monitor.
> - `margins` Custom window margin settings.
>
> Utilize o debug atalho e acompanhe no console o nome dos monitores com são reconhecidos.
> 
> ```lua
> hs.hotkey.bind({ "rightAlt", "rightShift" }, "m", function()
>   local managerMonitorsMac = require("common.manager_monitors_mac")
>   managerMonitorsMac.printConnectedMonitors()
> end))
> ```




## Usage

```lua
-- Move to Monitor 1 (option + 1)
local WindowGenerator = require("common.window_generator")

hs.hotkey.bind({ "alt" }, "1", function() --hotkey
  spoon.MonitorWindowApp:moveToMonitor("builtin_standard_margin_spaceleft", true) --positionID, shouldSave
end)

```
