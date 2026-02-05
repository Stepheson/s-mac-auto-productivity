local module = {}
module.name = "Create File"
module.version = "1.0"
module.author = "Antigravity"
module.description = "Creates a new file in the current Finder directory."

-- Function to return menu items
function module.getMenuItems(options)
    return {
        {
            text = "Create File...",
            subText = "Create a new file in current folder",
            action = function()
                module.promptAndCreate()
            end
        }
    }
end

-- Function to get the current Finder path using AppleScript
function module.getFinderPath()
    local script = [[
        tell application "Finder"
            try
                if exists Finder window 1 then
                    set currentFolder to target of Finder window 1 as alias
                    return POSIX path of currentFolder
                else
                    return POSIX path of (path to desktop)
                end
            on error
                return POSIX path of (path to desktop)
            end try
        end tell
    ]]
    local success, path = hs.osascript.applescript(script)
    if success and path then
        -- AppleScript results often contain a newline at the end
        return path:gsub("\n", "")
    else
        return nil
    end
end

-- Function to prompt for filename and create it
function module.promptAndCreate()
    local path = module.getFinderPath()
    if not path then
        hs.alert.show("Could not determine current folder.")
        return
    end

    local button, filename = hs.dialog.textPrompt("Create File", "Enter filename (e.g., notes.txt):", "", "Create",
        "Cancel")

    if button == "Create" and filename and filename ~= "" then
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
