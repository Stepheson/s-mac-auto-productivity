--- === EasyLoadModules ===
---
--- A Spoon to manage modules and centralized window generation.
--- It acts as a "Plugin Hub" for small automation scripts.

-- Font of icon create_file_icon.png: https://www.pngwing.com/

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "EasyLoadModules"
obj.version = "1.0"
obj.author = "Stepheson Alves"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT"

-- Load Window Generator
local windowGenerator = require("common.WindowGenerator")

-- Internal variables
obj.chooser = nil
obj.availableModules = {}
obj.settings = {} -- Store loaded JSON settings
obj.settingsFile = hs.configdir .. "/EasyLoadModulesSettings.json"

-- Function to load settings from JSON
function obj:loadSettings()
    local attr = hs.fs.attributes(self.settingsFile)
    if not attr then
        print("EasyLoadModules: Settings file not found at " .. tostring(self.settingsFile))
        self.settings = {}
        return
    end

    local content = io.open(self.settingsFile, "r"):read("*a")
    local success, data = pcall(hs.json.decode, content)

    if success and type(data) == "table" then
        self.settings = data
    else
        print("EasyLoadModules: Error decoding settings: " .. tostring(data))
        self.settings = {}
    end
end

-- Helper to parse dynamic parameters strings into a table
-- Matches module names case-insensitively
local function parseParams(params)
    local options = {}
    if not params or type(params) ~= "table" then return options end

    for _, param in ipairs(params) do
        -- Structure: module:command:mode (legacy format support)
        local parts = {}
        for part in string.gmatch(param, "[^:]+") do
            table.insert(parts, part)
        end

        if #parts >= 3 then
            local modName = parts[1]:lower()
            local cmdName = parts[2]
            local mode = parts[3]
            if not options[modName] then options[modName] = {} end
            options[modName][cmdName] = mode
        end
    end
    return options
end

-- Function to dynamically load modules from the 'modules' directory
function obj:loadModules()
    local scriptPath = hs.spoons.scriptPath()
    if not scriptPath then
        print("EasyLoadModules: ERROR - scriptPath is nil")
        return
    end

    local modulesPath = scriptPath .. "modules/"

    if not hs.fs.attributes(modulesPath) then
        print("EasyLoadModules: ERROR - Directory not found: " .. modulesPath)
        return
    end

    print("EasyLoadModules: Scanning modules in " .. modulesPath)
    for file in hs.fs.dir(modulesPath) do
        if file ~= "." and file ~= ".." then
            local attr = hs.fs.attributes(modulesPath .. file)
            if attr and attr.mode == "file" and file:sub(-4) == ".lua" then
                local loadPath = modulesPath .. file
                local success, module = pcall(dofile, loadPath)
                if success and type(module) == "table" and module.name then
                    -- Store by internal name
                    module.spoonPath = scriptPath
                    obj.availableModules[module.name] = module
                    print("EasyLoadModules: Registered module '" .. module.name .. "'")
                end
            end
        end
    end
end

-- Function to aggregate menu items from all modules
function obj:buildMenu(params)
    -- Load latest settings every time menu is built (hot-reload config)
    self:loadSettings()

    -- Parse dynamic params (if any provided via hotkey override)
    -- Note: We merge Dynamic Params ON TOP of JSON Params
    local dynamicOptions = parseParams(params or {})

    local items = {}

    -- Sort modules
    local names = {}
    local used = {}

    -- 1. Add ordered modules
    local order = self.settings.menu_order or {}
    for _, name in ipairs(order) do
        -- Check if module exists (case-insensitive key match attempt)
        -- self.availableModules keys are mixed case (e.g. "Dock", "Finder")
        -- order keys might be lowercase "dock".
        -- We need to find the matching real key.
        for modName, _ in pairs(self.availableModules) do
            if modName:lower() == name:lower() and not used[modName] then
                table.insert(names, modName)
                used[modName] = true
                break
            end
        end
    end

    -- 2. Add remaining modules alphabetically
    local remaining = {}
    for name, _ in pairs(self.availableModules) do
        if not used[name] then
            table.insert(remaining, name)
        end
    end
    table.sort(remaining)

    for _, name in ipairs(remaining) do
        table.insert(names, name)
    end

    for _, name in ipairs(names) do
        local mod = self.availableModules[name]
        if mod.getMenuItems then
            -- Prepare configuration for this module
            -- 1. Get Settings from JSON (using lowercase keys usually)
            -- We assume settings keys match module names (e.g. "finder", "dock")
            local modSettings = self.settings[name:lower()] or {}

            -- 2. Merge/Override with Dynamic Options
            local modDynamic = dynamicOptions[name:lower()] or {}

            -- Combine (Lua table merge shallow)
            local combinedOptions = {}
            for k, v in pairs(modSettings) do combinedOptions[k] = v end
            for k, v in pairs(modDynamic) do combinedOptions[k] = v end

            -- Call Module
            local modItems = mod:getMenuItems(combinedOptions)

            if modItems then
                for _, item in ipairs(modItems) do
                    -- Compatibility Mapping

                    -- Handle Legacy 'toggle' type (Dock, Finder)
                    if item.type == "toggle" and item.states and item.currentIndex then
                        -- Logic: Find the NEXT state to toggle to.
                        -- currentIndex is usually 1-based index of CURRENT state.
                        -- We want the action of the OTHER state.

                        local nextIndex = item.currentIndex + 1
                        if nextIndex > #item.states then nextIndex = 1 end

                        local nextState = item.states[nextIndex]

                        if nextState and nextState.action then
                            item.action = nextState.action
                            -- Optional: update subText to indicate what clicking will do
                            -- item.subText = (item.description or "") .. " (Click to " .. nextState.label .. ")"
                        else
                            print("EasyLoadModules: Error - Toggle item missing next state action")
                        end
                    end

                    item.text = item.label or item.text
                    item.subText = item.description or item.subText

                    table.insert(items, item)
                end
            end
        end
    end

    if #items == 0 then
        table.insert(items, { text = "No items found", subText = "Check settings or modules", valid = false })
    end

    -- Add Help
    table.insert(items, {
        text = "Help",
        subText = "Print available modules to Console",
        action = function()
            -- Simple help print
            for name, _ in pairs(self.availableModules) do print("Module: " .. name) end
            hs.alert.show("Check Console for details")
        end
    })

    return items
end

-- Init
function obj:init()
    -- Add Spoon path to package.path to allow internal requires
    local scriptPath = hs.spoons.scriptPath()
    if scriptPath then
        package.path = package.path .. ";" .. scriptPath .. "?.lua"
    end

    self:loadModules()
    self:loadSettings()

    -- Register with WindowGenerator
    -- Flattened by default as this is the Main Menu provider
    -- IMPORTANT: We pass 'config' with rootItems=true
    windowGenerator:register("EasyLoadModules", "Main Menu", function() return obj:buildMenu() end, { rootItems = true })
end

return obj
