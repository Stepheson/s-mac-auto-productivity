local obj = {}
obj.name = "Dock"
obj.version = "1.1"
obj.author = "Stepheson Alves"
obj.description = "Manages Dock auto-hide settings."
obj.parameter_schema = {}

-- Function to toggle Dock auto-hide
function obj.toggleDockAutoHide()
    local output, status = hs.execute("defaults read com.apple.dock autohide")
    local currentState = (output and output:gsub("%s+", "") == "1")

    local newState = not currentState
    local newStateStr = newState and "true" or "false"

    hs.task.new("/usr/bin/defaults", nil, { "write", "com.apple.dock", "autohide", "-bool", newStateStr }):start()

    local msg = newState and "Dock: Auto-Hide Enabled" or "Dock: Auto-Hide Disabled"
    hs.alert.show(msg)

    hs.task.new("/usr/bin/killall", nil, { "Dock" }):start()
end

-- Function to get current state
function obj.getDockAutoHideState()
    local output, status = hs.execute("defaults read com.apple.dock autohide")
    if output then
        return output:gsub("%s+", "") -- Trim whitespace
    end
    return "0"
end

-- Function to return menu items
function obj.getMenuItems()
    local state = obj.getDockAutoHideState()
    local isEnabled = (state == "1" or state == "true")

    local prefix = isEnabled and "(*) " or "( ) "
    local actionText = isEnabled and "Disable Dock Auto-Hide" or "Enable Dock Auto-Hide"

    return {
        {
            text = prefix .. "Toggle Dock Auto-Hide",
            subText = "Current: " .. (isEnabled and "Enabled" or "Disabled"),
            func = obj.toggleDockAutoHide
        }
    }
end

return obj
