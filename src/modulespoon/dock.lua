local module = {}
module.name = "Dock"
module.version = "1.1"
module.author = "Stepheson Alves"
module.description = "Manages Dock auto-hide settings."
module.parameter_schema = {}

local systemUtils = require("common.system_utils")

-- Function to return menu items (Schema)
function module.getMenuItems()
    local state = module.getDockAutoHideState()
    local isEnabled = (state == "1" or state == "true")

    return {
        {
            type = "toggle",
            label = "Dock Auto-Hide",
            image = hs.image.imageFromPath(hs.configdir .. "/modulespoon/images/autoHidden_dock_icon.png"),
            description = "Toggle Dock auto-hide setting",
            currentIndex = isEnabled and 2 or 1, -- 1=Disabled, 2=Enabled
            states = {
                {
                    label = "Disabled",
                    action = module.toggleDockAutoHide
                },
                {
                    label = "Enabled",
                    action = module.toggleDockAutoHide
                }
            }
        }
    }
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Function to toggle Dock auto-hide
function module.toggleDockAutoHide()
    local output, status = hs.execute("defaults read com.apple.dock autohide")
    local currentState = (output and output:gsub("%s+", "") == "1")

    local newState = not currentState
    local newStateStr = newState and "true" or "false"

    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.dock", "autohide", "-bool", newStateStr }):start()
    print("Dock: Executed defaults write autohide " .. newStateStr)

    local msg = newState and "Dock: Auto-Hide Enabled" or "Dock: Auto-Hide Disabled"
    hs.alert.show(msg)

    systemUtils.killApp("Dock")
    print("Dock: Executed killall Dock")
end

-- Function to get current state
function module.getDockAutoHideState()
    local output, status = hs.execute("defaults read com.apple.dock autohide")
    if output then
        return output:gsub("%s+", "") -- Trim whitespace
    end
    return "0"
end

return module
