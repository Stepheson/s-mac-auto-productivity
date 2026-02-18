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
local isActive = true -- Default to active (started) unless stopped explicitly

-- ========== HOTKEY MANAGEMENT ==========

--- Register hotkey objects for management
-- @param input table|userdata List of hotkeys OR a single hotkey object
function obj:register(input)
    if not input then return self end

    local function add(hk)
        table.insert(registeredHotkeys, hk)
        if isActive then
            hk:enable()
        else
            hk:disable()
        end
    end

    -- Check if it's a list (table and not a hotkey object)
    -- hs.hotkey objects are userdata or tables with metamethods, but usually we can check for 'enable'
    if type(input) == "table" and not (input.enable and input.disable) then
        -- Assume list
        for _, hk in ipairs(input) do
            add(hk)
        end
    else
        -- Assume single object
        add(input)
    end

    return self
end

--- Deprecated: Alias for backward compatibility
function obj:registerHotkeys(hotkeys)
    return self:register(hotkeys)
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
