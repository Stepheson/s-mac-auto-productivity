--- === SpeedMacosCustomConfigs ===
---
--- A Spoon to manage macOS configurations via a dynamic menu.
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "SpeedMacosCustomConfigs"
obj.version = "1.0"
obj.author = "Stepheson Alves"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internal variables
obj.chooser = nil
obj.menuItems = {}

-- Load modules
local scriptPath = hs.spoons.scriptPath()
print("SpeedMacosCustomConfigs: scriptPath is " .. tostring(scriptPath))

local function loadModule(moduleName)
    local modulePath = scriptPath .. "modules/" .. moduleName .. ".lua"
    print("SpeedMacosCustomConfigs: Loading " .. moduleName .. " from " .. modulePath)
    local success, module = pcall(dofile, modulePath)
    if not success then
        print("SpeedMacosCustomConfigs: Error loading " .. moduleName .. ": " .. module)
        return nil
    end
    return module
end

local finder = loadModule("finder")
local screenshot = loadModule("screenshot")
local dock = loadModule("dock")

-- Function to aggregate menu items from all modules
function obj:buildMenu()
    print("SpeedMacosCustomConfigs: Building menu...")
    self.menuItems = {}
    self.menuActions = {} -- Store functions here

    -- Helper to add items
    local function addItems(items)
        if items and type(items) == "table" then
            for _, item in ipairs(items) do
                -- Store the function separately
                if item.func then
                    table.insert(self.menuActions, item.func)
                    item.func = nil                                -- Remove function from the item passed to chooser
                else
                    table.insert(self.menuActions, function() end) -- Placeholder
                end

                -- Add index to item for lookup
                item.index = #self.menuActions
                table.insert(self.menuItems, item)
            end
        else
            print("SpeedMacosCustomConfigs: Warning - items is invalid")
        end
    end

    -- Add items from modules
    if finder then
        addItems(finder.getMenuItems())
    else
        table.insert(self.menuItems, { text = "Error: Finder module not loaded", subText = "Check console for details" })
        table.insert(self.menuActions, function() end)
    end

    if screenshot then
        addItems(screenshot.getMenuItems())
    else
        table.insert(self.menuItems,
            { text = "Error: Screenshot module not loaded", subText = "Check console for details" })
        table.insert(self.menuActions, function() end)
    end

    if dock then
        addItems(dock.getMenuItems())
    else
        table.insert(self.menuItems, { text = "Error: Dock module not loaded", subText = "Check console for details" })
        table.insert(self.menuActions, function() end)
    end

    if #self.menuItems == 0 then
        table.insert(self.menuItems, { text = "No items found", subText = "Modules loaded but returned no items" })
        table.insert(self.menuActions, function() end)
    end

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
function obj:showMenu()
    if not self.chooser then
        self.chooser = hs.chooser.new(function(choice) self:onChoice(choice) end)
    end

    self:buildMenu()
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

return obj
