--- === SpeedMacosCustomConfigs ===
---
--- A Spoon to manage macOS configurations via a dynamic menu.
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "SpeedMacosCustomConfigs"
obj.version = "1.1"
obj.author = "Stepheson Alves"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal variables
obj.chooser = nil
obj.menuItems = {}
obj.availableModules = {} -- Store loaded module objects keyed by internal name

-- Helper to parse parameters: ["finder:hiddenfiles:forced"] -> { Finder = { hiddenfiles = "forced" } }
-- Note: Keys here are matched against module.name (case-sensitive usually, but we can normalize)
local function parseParams(params)
    local options = {}
    if not params or type(params) ~= "table" then return options end

    for _, param in ipairs(params) do
        -- Structure: module:command:mode
        local parts = {}
        for part in string.gmatch(param, "[^:]+") do
            table.insert(parts, part)
        end

        if #parts >= 3 then
            local modName = parts[1] -- e.g. "finder"
            local cmdName = parts[2]
            local mode = parts[3]

            -- Normalize modName to lowercase for matching, or keep as is?
            -- Strategy: User types "finder", module name is "Finder". We'll match case-insensitively.
            local key = modName:lower()

            if not options[key] then options[key] = {} end
            options[key][cmdName] = mode
        end
    end
    return options
end

-- Function to dynamically load modules from the 'modules' directory
function obj:loadModules()
    local scriptPath = hs.spoons.scriptPath()
    local modulesPath = scriptPath .. "modules/"

    print("SpeedMacosCustomConfigs: Scanning modules in " .. modulesPath)

    -- Iterate over files in modules directory
    for file in hs.fs.dir(modulesPath) do
        if file ~= "." and file ~= ".." then
            local attr = hs.fs.attributes(modulesPath .. file)
            if attr and attr.mode == "file" and file:sub(-4) == ".lua" then
                local moduleName = file:sub(1, -5) -- remove .lua
                local loadPath = modulesPath .. file

                local success, module = pcall(dofile, loadPath)
                if success and type(module) == "table" then
                    -- Validate metadata interface
                    if module.name then
                        -- Store by internal name (e.g., "Finder")
                        obj.availableModules[module.name] = module
                        print("SpeedMacosCustomConfigs: Registered module '" .. module.name .. "' (" .. file .. ")")
                    else
                        print("SpeedMacosCustomConfigs: Skipped " .. file .. " (Missing 'name' metadata)")
                    end
                else
                    print("SpeedMacosCustomConfigs: Error loading " .. file .. ": " .. tostring(module))
                end
            end
        end
    end
end

-- Function to help/list modules
function obj:help()
    local helpText = "Available Modules in SpeedMacosCustomConfigs:\n\n"

    local names = {}
    for name, _ in pairs(self.availableModules) do
        table.insert(names, name)
    end
    table.sort(names)

    for _, name in ipairs(names) do
        local mod = self.availableModules[name]
        helpText = helpText .. "• " .. mod.name .. "\n"
        if mod.description then
            helpText = helpText .. "  Desc: " .. mod.description .. "\n"
        end
        if mod.parameter_schema and #mod.parameter_schema > 0 then
            helpText = helpText .. "  Params: " .. table.concat(mod.parameter_schema, ", ") .. "\n"
        end
        helpText = helpText .. "\n"
    end

    hs.alert.show("Check Console for Help Details", 2)
    print(helpText)
    return self
end

-- Function to aggregate menu items from all modules
function obj:buildMenu(params)
    print("SpeedMacosCustomConfigs: Building menu...")
    self.menuItems = {}
    self.menuActions = {}

    local options = parseParams(params)

    -- Helper to add items
    local function addItems(items)
        if items and type(items) == "table" then
            for _, item in ipairs(items) do
                if item.func then
                    table.insert(self.menuActions, item.func)
                    item.func = nil
                else
                    table.insert(self.menuActions, function() end)
                end
                item.index = #self.menuActions
                table.insert(self.menuItems, item)
            end
        end
    end

    -- Sort modules by name for consistent menu order
    local names = {}
    for name, _ in pairs(self.availableModules) do
        table.insert(names, name)
    end
    table.sort(names)

    -- Add items from each module
    for _, name in ipairs(names) do
        local mod = self.availableModules[name]
        if mod.getMenuItems then
            -- Match options case-insensitively
            -- options keys are lowercased in parseParams (if we enforce it)
            -- Let's check options["finder"] for module.name="Finder"
            local modOptions = options[name:lower()]

            addItems(mod:getMenuItems(modOptions))
        end
    end

    if #self.menuItems == 0 then
        table.insert(self.menuItems, { text = "No items found", subText = "Modules loaded but returned no items" })
        table.insert(self.menuActions, function() end)
    end

    -- Add "Help" option at the end
    table.insert(self.menuActions, function() obj:help() end)
    table.insert(self.menuItems, {
        text = "Help / List Modules",
        subText = "Print available modules and parameters to Console",
        index = #self.menuActions
    })

    print("SpeedMacosCustomConfigs: Menu built with " .. #self.menuItems .. " items")
end

-- Function to handle menu selection
function obj:onChoice(choice)
    if choice and choice.index then
        local action = self.menuActions[choice.index]
        if action then
            action()
        end
    end
end

-- Function to show the menu
function obj:showMenu(params)
    if not self.chooser then
        self.chooser = hs.chooser.new(function(choice) self:onChoice(choice) end)
    end

    self:buildMenu(params)
    self.chooser:choices(self.menuItems)
    self.chooser:show()
end

-- Function to bind hotkeys
function obj:bindHotkeys(mapping)
    if mapping["show_menu"] then
        if self.hotkey then
            self.hotkey:delete()
        end
        self.hotkey = hs.hotkey.bind(mapping["show_menu"][1], mapping["show_menu"][2], function()
            self:showMenu()
        end)
    end
end

-- Init
function obj:init()
    -- Load modules on initialization
    self:loadModules()
    return self
end

return obj
