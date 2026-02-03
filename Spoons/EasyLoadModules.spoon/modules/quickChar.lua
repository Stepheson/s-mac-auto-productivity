-- QuickChar Module for EasyLoadModules
-- Replaces QuickCharAccess Spoon

local module = {}
module.name = "QuickChar"
module.version = "1.0"
module.author = "Stepheson Alves"
module.description = "Quickly copy special characters to clipboard"


-- Required for WindowGenerator compatibility
module.parameter_schema = {}

--- Generate Menu Items
--- @param params table Configuration passed from EasyLoadModules (contains parsed JSON settings)
function module:getMenuItems(params)
    local items = {}

    -- Params should contain the list of characters from EasyLoadModulesSettings.json
    -- The structure in JSON is keys "quickChar": [...] (list of objects)
    -- So params passed here might represent the merged options for this module.

    -- Params handling:
    -- 1. If params is an array-like table (list of chars), use it directly.
    -- 2. If params is a config table (like { quickchar = [...] }), try to extract. (Should be handled by init.lua merging, but safety first)

    local chars = params

    -- Debugging aid
    if not chars or #chars == 0 then
        -- Fallback check: Did we get the parent table?
        if params and params.quickchar then
            chars = params.quickchar
        end
    end

    if not chars or #chars == 0 then
        table.insert(items, {
            text = "No characters configured",
            subText = "Add 'quickChar' list to EasyLoadModulesSettings.json",
            valid = false
        })
        return items
    end

    -- Create a submenu entry that opens the list of characters
    -- WAIT: If we return a list here, they are added to the menu.
    -- If 'rootItems=true' is on EasyLoadModules, these items appear in main menu?
    -- The user wanted QuickCharAccess to remain separate (nested).
    -- So we should return a SINGLE item that opens a submenu with the characters.

    local charItems = {}
    for _, item in ipairs(chars) do
        table.insert(charItems, {
            char = item.char, -- Special WindowGenerator field
            label = item.label,
            text = item.label,
            action = function()
                hs.pasteboard.setContents(item.char)
                hs.alert.show("Copied: " .. item.char)
            end
        })
    end

    -- Return a single item handling the submenu
    table.insert(items, {
        text = "Quick Char Access",
        subText = "Browse and copy special characters",
        menu = charItems -- WindowGenerator handles 'menu' field recursively!
    })

    return items
end

return module
