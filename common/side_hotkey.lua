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

local KOD_LEFT_ALT    = 58
local KOD_RIGHT_ALT   = 61
local KOD_LEFT_CMD    = 55
local KOD_RIGHT_CMD   = 54
local KOD_LEFT_SHIFT  = 56
local KOD_RIGHT_SHIFT = 60
local KOD_LEFT_CTRL   = 59
local KOD_RIGHT_CTRL  = 62



SideHotkey.activeSideCodes = {}

local function updateModifierState(event)
    local code = event:getKeyCode()
    local flags = event:getFlags()

    -- Helper to handle toggle logic with safety cleanup
    local function handleModifier(leftCode, rightCode, flagState)
        if not flagState then
            SideHotkey.activeSideCodes[leftCode] = nil
            SideHotkey.activeSideCodes[rightCode] = nil
        else
            if code == leftCode or code == rightCode then
                if SideHotkey.activeSideCodes[code] then
                    SideHotkey.activeSideCodes[code] = nil
                else
                    SideHotkey.activeSideCodes[code] = true
                end
            end
        end
    end

    handleModifier(KOD_LEFT_ALT, KOD_RIGHT_ALT, flags.alt)
    handleModifier(KOD_LEFT_CMD, KOD_RIGHT_CMD, flags.cmd)
    handleModifier(KOD_LEFT_SHIFT, KOD_RIGHT_SHIFT, flags.shift)
    handleModifier(KOD_LEFT_CTRL, KOD_RIGHT_CTRL, flags.ctrl)

    return false
end

SideHotkey.tracker = eventtap.new({ eventTypes.flagsChanged }, updateModifierState)
SideHotkey.tracker:start()

local function checkModifiers(requiredMods)
    local currentFlags = hs.eventtap.checkKeyboardModifiers()

    local requiredSet = {
        alt = false,
        cmd = false,
        shift = false,
        ctrl = false,
        -- Specifics
        leftAlt = false,
        rightAlt = false,
        leftCmd = false,
        rightCmd = false,
        leftShift = false,
        rightShift = false,
        leftCtrl = false,
        rightCtrl = false
    }

    for _, mod in ipairs(requiredMods) do
        requiredSet[mod] = true

        if mod == "leftAlt" or mod == "rightAlt" then requiredSet.alt = true end
        if mod == "leftCmd" or mod == "rightCmd" then requiredSet.cmd = true end
        if mod == "leftShift" or mod == "rightShift" then requiredSet.shift = true end
        if mod == "leftCtrl" or mod == "rightCtrl" then requiredSet.ctrl = true end
    end

    -- 2. Verify all REQUIRED modifiers are present
    for _, mod in ipairs(requiredMods) do
        if mod == "leftAlt" then
            if not (currentFlags.alt and SideHotkey.activeSideCodes[KOD_LEFT_ALT]) then return false end
        elseif mod == "rightAlt" then
            if not (currentFlags.alt and SideHotkey.activeSideCodes[KOD_RIGHT_ALT]) then return false end
        elseif mod == "leftCmd" then
            if not (currentFlags.cmd and SideHotkey.activeSideCodes[KOD_LEFT_CMD]) then return false end
        elseif mod == "rightCmd" then
            if not (currentFlags.cmd and SideHotkey.activeSideCodes[KOD_RIGHT_CMD]) then return false end
        elseif mod == "leftShift" then
            if not (currentFlags.shift and SideHotkey.activeSideCodes[KOD_LEFT_SHIFT]) then return false end
        elseif mod == "rightShift" then
            if not (currentFlags.shift and SideHotkey.activeSideCodes[KOD_RIGHT_SHIFT]) then return false end
        elseif mod == "leftCtrl" then
            if not (currentFlags.ctrl and SideHotkey.activeSideCodes[KOD_LEFT_CTRL]) then return false end
        elseif mod == "rightCtrl" then
            if not (currentFlags.ctrl and SideHotkey.activeSideCodes[KOD_RIGHT_CTRL]) then return false end
        else
            -- Generic
            if not currentFlags[mod] then return false end
        end
    end

    -- 3. Verify NO EXTRA modifiers are present (Strict Matching)
    -- Check generics: if currentFlags has 'alt' but we didn't require it, fail.
    if currentFlags.alt and not requiredSet.alt then return false end
    if currentFlags.cmd and not requiredSet.cmd then return false end
    if currentFlags.shift and not requiredSet.shift then return false end
    if currentFlags.ctrl and not requiredSet.ctrl then return false end

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
