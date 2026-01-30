--- === AutomationControl ===
---
--- Centralized control for Hammerspoon automation
--- Handles lifecycle (start/stop) for registered hotkeys and Spoons
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AutomationControl"
obj.version = "1.4"
obj.author = "Stepheson Alves"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal state
local registeredHotkeys = {}
local registeredSpoons = {}
local isActive = false

-- ========== HOTKEY MANAGEMENT ==========

--- Register existing hotkey objects for management
-- @param hotkeys table List of hs.hotkey objects
function obj:registerHotkeys(hotkeys)
    if not hotkeys or type(hotkeys) ~= "table" then
        return self
    end

    for _, hk in ipairs(hotkeys) do
        table.insert(registeredHotkeys, hk)

        -- Sync state: if active, enable; if inactive, disable
        if isActive then
            hk:enable()
        else
            hk:disable()
        end
    end

    return self
end

--- Enable managed hotkeys
local function enableAllHotkeys()
    for _, hk in ipairs(registeredHotkeys) do
        hk:enable()
    end
end

--- Disable managed hotkeys
local function disableAllHotkeys()
    for _, hk in ipairs(registeredHotkeys) do
        hk:disable()
    end
end

-- ========== SPOON REGISTRY ==========

--- Register a Spoon to be tracked (for status alerts)
-- @param spoonObj table The Spoon object
function obj:registerSpoon(spoonObj)
    if spoonObj and spoonObj.name then
        table.insert(registeredSpoons, spoonObj)
    end
    return self
end

-- ========== LIFECYCLE ==========

--- Start automation (enable managed hotkeys)
function obj:start()
    print("AutomationControl: start() called")
    if isActive then
        print("AutomationControl: already active")
        return self
    end

    isActive = true
    print("AutomationControl: enabling hotkeys")
    enableAllHotkeys()

    -- Start registered spoons
    print("AutomationControl: starting spoons")
    for _, s in ipairs(registeredSpoons) do
        print("AutomationControl: checking spoon " .. tostring(s.name))
        if s.start then
            print("AutomationControl: starting spoon " .. tostring(s.name))
            local status, err = pcall(function() s:start() end)
            if not status then
                print("AutomationControl: ERROR starting spoon " .. tostring(s.name) .. ": " .. tostring(err))
                hs.alert.show("⚠️ Error starting " .. tostring(s.name))
            end
        end
    end

    -- Show status
    print("AutomationControl: showing status")
    local spoonNames = {}
    for _, s in ipairs(registeredSpoons) do
        table.insert(spoonNames, "• " .. s.name)
    end

    local message = "Automation Active\n" .. table.concat(spoonNames, "\n")
    hs.alert.show("🟢 " .. message)

    return self
end

--- Stop automation (disable managed hotkeys)
function obj:stop()
    if not isActive then return self end

    isActive = false
    disableAllHotkeys()

    -- Stop registered spoons
    for _, s in ipairs(registeredSpoons) do
        if s.stop then s:stop() end
    end

    hs.alert.show("🔴 Automation Paused")

    return self
end

--- Toggle automation state
function obj:toggle()
    if isActive then
        self:stop()
    else
        self:start()
    end
end

--- Initialize the Spoon
function obj:init()
    return self
end

return obj
