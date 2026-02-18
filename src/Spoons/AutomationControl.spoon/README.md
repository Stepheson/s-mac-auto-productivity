# AutomationControl Spoon

**Goal**: The central manager. It controls the lifecycle (Start/Stop) of other Spoons and hotkeys.

## Features

- **Master Switch**: Global Pause/Resume for all automation hotkeys.
- **Visual Feedback**: Shows alerts when Paused (🔴) or Resumed (🟢).
- **Safety**: Prevents accidental triggers when you need the system to be "native".

## Usage

Registered via `init.lua`.

```lua
-- Stop (Pause)
spoon.AutomationControl:stop()

-- Start (Resume)
spoon.AutomationControl:start()
```

# ⌨️ Configuration

To enable `AutomationControl` to manage your shortcuts, you must register them explicitly and start the Spoon in your [init.lua](cci:7://file:///Users/stephesonalves/Projects/Developing/Automations/s-mac-auto-productivity/src/init.lua:0:0-0:0).

**1. Register Hotkeys:**
Wrap your hotkey definitions using `spoon.AutomationControl:register()` instead of just binding them.

```lua
-- Example: Registering a hotkey
spoon.AutomationControl:register(
    hs.hotkey.bind({ "alt" }, "7", function()
        spoon.Name1:Command()
    end)
)
```

**2. Register Spoons and Start:**
At the end of your init.lua, you must register all other Spoons you want to be controlled and then start AutomationControl.

```lua
if spoon.AutomationControl then
  -- Register dependent Spoons (optional, if they need specific management)
  spoon.AutomationControl:registerSpoon(spoon.Name1)
  spoon.AutomationControl:registerSpoon(spoon.Name2)
  -- Start the automation controller
  spoon.AutomationControl:start()
else
  print("⚠️ AutomationControl Spoon not found. Hotkeys active in unmanaged mode.")
end
```
