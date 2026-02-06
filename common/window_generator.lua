-- common/WindowGenerator.lua
-- Centralized Window/Menu Generator using hs.chooser
-- Acts as a hub for Spoons to register their commands.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowGenerator"
obj.version = "1.1"
obj.author = "Stepheson Alves"

-- Storage
obj.registeredSpoons = {} -- { [name] = { title = "...", generator = func } }
obj.chooser = nil
obj.historyStack = {}     -- For breadcrumb navigation
obj.activeMap = {}        -- Maps choice index (or uuid) to actual item logic

-- Helper: Process items for chooser (Sanitize for LuaSkin)
local function processItems(items)
    obj.activeMap = {} -- Clear previous map
    local choices = {}

    for i, item in ipairs(items) do
        -- Store the full logic item in our internal map using index as key
        -- We purposely do NOT put 'action' or 'originalItem' in the choice table sent to hs.chooser
        -- because passing Lua functions/tables to the C-side bridge causes crashes (LuaSkin errors).
        obj.activeMap[i] = item

        local choice = {
            text = item.label or item.text or "Unknown",
            subText = item.description or item.subText or "",
            image = item.image,
            valid = true,
            uuid = tostring(i), -- Pass ID as string to be safe
        }

        -- Special handling for "Char" grid simulation (Icon + Text)
        if item.char then
            -- Added extra spaces for margin
            choice.text = item.char .. "       " .. (item.label or "")
            if not item.description then
                choice.subText = "Copy to clipboard"
            end
        end

        table.insert(choices, choice)
    end
    return choices
end

-- Callback for selection
local function onChoice(choice)
    if not choice then return end -- Cancelled

    local index = tonumber(choice.uuid)
    local item = obj.activeMap[index]

    if not item then
        -- This might happen if 'isBack' logic didn't use same map structure.
        -- If it's a Back button, we might have injected it separately?
        -- Let's check if it's our transient Back item logic handling?
        -- No, let's look at how we insert Back.

        print("WindowGenerator: Error - No item found for index " .. tostring(index))
        return
    end

    -- Handle Back Button
    if item.isBack then
        local prev = table.remove(obj.historyStack)
        if prev then
            obj:showMenu(prev.items, prev.placeholder)
        else
            obj:showMain()
        end
        return
    end

    -- Execute Action
    if item.action then
        item.action()
        return -- Close chooser (default)
    end

    -- Handle Submenu (Recursive)
    if item.items or item.menu then
        local subItems = item.items or item.menu
        -- Push to history
        table.insert(obj.historyStack, {
            items = obj.currentItems,
            placeholder = obj.currentPlaceholder
        })
        obj:showMenu(subItems, item.label)
    end
end

--- Show a native input box (AppleScript dialog) with optional custom icon
-- @param title string The window title
-- @param message string The message inside the dialog
-- @param defaultText string Default input text
-- @param buttonText string The confirm button label
-- @param iconPath string (optional) Absolute path to a custom icon (file reference)
-- @return string|nil The returned text if confirmed, or nil if cancelled
function obj:showInputBox(title, message, defaultText, buttonText, iconPath)
    local iconClause = ""
    if iconPath and iconPath ~= "" then
        iconClause = 'with icon (POSIX file "' .. iconPath .. '")'
    end

    local script = string.format([[
        try
            tell application "System Events"
                activate
                display dialog "%s" default answer "%s" with title "%s" buttons {"Cancel", "%s"} default button "%s" %s
            end tell
            return {button returned of result, text returned of result}
        on error
            return {"Cancel", ""}
        end try
    ]], message, defaultText, title, buttonText, buttonText, iconClause)

    local success, result = hs.osascript.applescript(script)

    if success and type(result) == "table" and #result == 2 then
        local button = result[1]
        local text = result[2]
        if button == buttonText then
            return text
        end
    end
    return nil
end

--- Register a Spoon's menu generator
--- @param name string Unique ID for the spoon (e.g., "QuickCharAccess")
--- @param title string Human readable title
--- @param generatorFunc function Function that returns a list of items
--- @param config table|nil Configuration options (e.g., { rootItems = true })
function obj:register(name, title, generatorFunc, config)
    obj.registeredSpoons[name] = {
        title = title,
        generator = generatorFunc,
        config = config or {}
    }
end

--- Internal: Show a specific list of items
function obj:showMenu(items, placeholder)
    if not obj.chooser then
        obj.chooser = hs.chooser.new(onChoice)
        obj.chooser:bgDark(true) -- Dark mode preference
    end

    -- Dynamic Sizing Logic (Refactored to manager_monitors_mac)
    local monitorManager = require("common.manager_monitors_mac")

    -- Default Ratios
    local LANDSCAPE_WIDTH = 0.25
    local PORTRAIT_WIDTH = 0.45 -- Wider on portrait (45%)
    local VERTICAL_OFFSET = 0.30

    local coords = monitorManager.getCenteredCoordinates(LANDSCAPE_WIDTH, PORTRAIT_WIDTH, VERTICAL_OFFSET)

    obj.chooser:width(coords.widthPct * 100)

    -- Add Back button if in history
    local hasBack = (#obj.historyStack > 0)
    local itemsToProcess = {}

    if hasBack then
        table.insert(itemsToProcess, {
            text = "⬅ Back",
            subText = "Return to previous menu",
            isBack = true
        })
    end

    for _, v in ipairs(items) do
        table.insert(itemsToProcess, v)
    end

    local displayItems = processItems(itemsToProcess)

    obj.currentItems = items -- Store raw items for history (breadcrumbs)
    obj.currentPlaceholder = placeholder

    obj.chooser:choices(displayItems)
    obj.chooser:placeholderText(placeholder or "Select Option")

    obj.chooser:show(coords.centerPoint)
end

--- Show the Main Menu (Aggregation of all Spoons)
function obj:showMain()
    obj.historyStack = {} -- Reset history
    local mainItems = {}

    for name, data in pairs(obj.registeredSpoons) do
        if data.config.rootItems then
            -- Flatten: Execute generator and add items directly
            local items = data.generator()
            if items then
                for _, item in ipairs(items) do
                    -- Optional: Prefix text with Title if confused? No, cleanest is just adding.
                    table.insert(mainItems, item)
                end
            end
        else
            -- Nested: Add single item to open submenu
            table.insert(mainItems, {
                text = data.title,
                subText = "Open " .. data.title .. " menu",
                action = function()
                    -- Generate fresh items on click, calling generator without params (Main Menu context)
                    local items = data.generator()

                    table.insert(obj.historyStack, {
                        items = mainItems,
                        placeholder = "Main Menu"
                    })
                    obj:showMenu(items, data.title)
                end,
            })
        end
    end

    -- Sort by text -- Removed to respect provider order
    -- table.sort(mainItems, function(a, b) return a.text < b.text end)

    obj:showMenu(mainItems, "Main Menu")
end

--- Show a specific Spoon's menu directly
--- @param spoonName string|nil Name of registered spoon. If nil, shows Main Menu.
--- @param params table|nil Optional parameters to pass to the generator function
function obj:show(spoonName, params)
    if not spoonName then
        obj:showMain()
        return
    end

    local data = obj.registeredSpoons[spoonName]
    if data then
        obj.historyStack = {} -- Reset history
        -- Pass params to generator if supported
        local items = data.generator(params)
        obj:showMenu(items, data.title)
    else
        hs.alert.show("WindowGenerator: Spoon '" .. spoonName .. "' not found.")
    end
end

return obj
