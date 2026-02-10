local module = {}
module.name = "Create File"
module.version = "1.1"
module.author = "Antigravity"
module.description = "Creates a new file in the current Finder directory."

local finderUtils = require("common.finder_utils")
local windowGenerator = require("common.window_generator")

-- Function to return menu items
function module.getMenuItems(options)
    return {
        {
            text = "Create File...",
            subText = "Create a new file in current folder",
            image = hs.image.imageFromPath(hs.configdir .. "/modulespoon/images/create_file_icon.png"),
            action = function()
                module.promptAndCreate()
            end
        }
    }
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Function to prompt for filename and create it
function module.promptAndCreate()
    local path = finderUtils.getCurrentPath()
    if not path then
        hs.alert.show("Could not determine current folder.")
        return
    end

    local filename = windowGenerator:showInputBox(
        "Create File",
        "Enter filename (e.g., notes.txt):",
        "",
        "Create",
        hs.configdir .. "/modulespoon/images/create_file_icon.png"
    )

    if filename and filename ~= "" then
        local fullPath = path .. filename

        -- Check if file exists to avoid overwriting
        if hs.fs.attributes(fullPath) then
            hs.alert.show("File already exists!")
            return
        end

        local file = io.open(fullPath, "w")
        if file then
            file:close()
            hs.alert.show("Created: " .. filename)

            -- Reveal in Finder (optional polish)
            hs.execute("open -R " .. string.format("%q", fullPath))
        else
            hs.alert.show("Failed to create file.")
        end
    end
end

return module
