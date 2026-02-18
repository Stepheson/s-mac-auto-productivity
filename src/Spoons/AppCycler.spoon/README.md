# AppCycler Spoon

**Goal**: An intelligent window switcher restricted to the **current monitor**. Avoids the chaos of jumping between screens.

## Modes

- **Mode 0 (Default)**: Cycles all windows on the current screen.
- **Mode 1**: Cycles windows only between different apps.
- **Mode 2**: Cycles instances only between instances of the same app.

## Usage

```lua
local AppCycler = spoon.AppCycler

-- Cycle windows on current monitor (Alt + Tab)
hs.hotkey.bind({ "alt" }, "tab", function()
    AppCycler:cycle(0)
end)
```
