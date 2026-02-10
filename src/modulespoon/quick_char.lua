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

    local chars = params

    -- Case 1: Params is the full settings table (e.g. { quickchar={...}, finder={...} })
    if chars and chars.quickchar then
        chars = chars.quickchar
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
        image = hs.image.imageFromPath(hs.configdir .. "/modulespoon/images/quickChar_icon.png"),
        menu = charItems -- WindowGenerator handles 'menu' field recursively!
    })

    return items
end

return module
