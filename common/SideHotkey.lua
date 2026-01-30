local eventtap = hs.eventtap
local eventTypes = hs.eventtap.event.types

local SideHotkey = {}
SideHotkey.bindings = {}
SideHotkey.debug = false -- Disable debug for production

-- Utility to normalize key names to keycodes
local function getKeyCode(key)
    local code = hs.keycodes.map[key]
    if not code then
        print("⚠️ SideHotkey: Invalid key '" .. tostring(key) .. "'")
        return nil
    end
    return code
end

-- CONSTANTS: Keycodes for Modifiers
local KOD_LEFT_ALT         = 58
local KOD_RIGHT_ALT        = 61
local KOD_LEFT_CMD         = 55
local KOD_RIGHT_CMD        = 54
local KOD_LEFT_SHIFT       = 56
local KOD_RIGHT_SHIFT      = 60
local KOD_LEFT_CTRL        = 59
local KOD_RIGHT_CTRL       = 62

-- Internal Modifier State (tracked manually)
local modState             = {
    leftAlt = false,
    rightAlt = false,
    leftCmd = false,
    rightCmd = false,
    leftShift = false,
    rightShift = false,
    leftCtrl = false,
    rightCtrl = false
}

-- REFINED TRACKER: Keep a set of active modifier codes
SideHotkey.activeSideCodes = {}

local function updateModifierState(event)
    local code = event:getKeyCode()
    local flags = event:getFlags()

    -- Determine if this key event resulted in the modifier being ACTIVE or INACTIVE.
    -- We assume standard mapping:
    local isAlt = (code == KOD_LEFT_ALT or code == KOD_RIGHT_ALT)
    local isCmd = (code == KOD_LEFT_CMD or code == KOD_RIGHT_CMD)
    local isShift = (code == KOD_LEFT_SHIFT or code == KOD_RIGHT_SHIFT)
    local isCtrl = (code == KOD_LEFT_CTRL or code == KOD_RIGHT_CTRL)

    local isActive = false
    if isAlt and flags.alt then isActive = true end
    if isCmd and flags.cmd then isActive = true end
    if isShift and flags.shift then isActive = true end
    if isCtrl and flags.ctrl then isActive = true end

    if isActive then
        SideHotkey.activeSideCodes[code] = true
    else
        SideHotkey.activeSideCodes[code] = nil
    end

    return false
end

SideHotkey.tracker = eventtap.new({ eventTypes.flagsChanged }, updateModifierState)
SideHotkey.tracker:start()

local function checkModifiers(requiredMods)
    local currentFlags = hs.eventtap.checkKeyboardModifiers()

    for _, mod in ipairs(requiredMods) do
        local requiredCode = nil
        local genericFlag = nil

        if mod == "leftAlt" then
            requiredCode = KOD_LEFT_ALT; genericFlag = "alt"
        elseif mod == "rightAlt" then
            requiredCode = KOD_RIGHT_ALT; genericFlag = "alt"
        elseif mod == "leftCmd" then
            requiredCode = KOD_LEFT_CMD; genericFlag = "cmd"
        elseif mod == "rightCmd" then
            requiredCode = KOD_RIGHT_CMD; genericFlag = "cmd"
        elseif mod == "leftShift" then
            requiredCode = KOD_LEFT_SHIFT; genericFlag = "shift"
        elseif mod == "rightShift" then
            requiredCode = KOD_RIGHT_SHIFT; genericFlag = "shift"
        end

        if requiredCode then
            -- 1. Must have generic flag
            if not currentFlags[genericFlag] then return false end
            -- 2. Must have specific code tracked
            if not SideHotkey.activeSideCodes[requiredCode] then return false end
        else
            -- Generic
            if mod == "alt" and not currentFlags.alt then return false end
            if mod == "shift" and not currentFlags.shift then return false end
            if mod == "cmd" and not currentFlags.cmd then return false end
            if mod == "ctrl" and not currentFlags.ctrl then return false end
        end
    end

    return true
end


-- The main event listener
SideHotkey.listener = eventtap.new({ eventTypes.keyDown }, function(event)
    local code = event:getKeyCode()

    for _, binding in ipairs(SideHotkey.bindings) do
        if binding.enabled and binding.keyCode == code then
            if checkModifiers(binding.modifiers) then
                local status, err = pcall(binding.fn)
                if not status then print("🔴 Error: " .. tostring(err)) end
                return true -- Consume event
            end
        end
    end
    return false
end)

function SideHotkey.bind(modifiers, key, fn)
    local code = getKeyCode(key)
    if not code then return end
    local binding = { modifiers = modifiers, keyCode = code, fn = fn, enabled = true }

    function binding:enable()
        self.enabled = true; return self
    end

    function binding:disable()
        self.enabled = false; return self
    end

    table.insert(SideHotkey.bindings, binding)
    if not SideHotkey.listener:isEnabled() then SideHotkey.listener:start() end
    return binding
end

function SideHotkey.unbindAll()
    SideHotkey.bindings = {}
    if SideHotkey.listener:isEnabled() then SideHotkey.listener:stop() end
end

return SideHotkey
