local finderUtils = {}

---
-- Get the POSIX path of the current Finder window or Desktop
-- @return string|nil The path or nil if failed
function finderUtils.getCurrentPath()
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

return finderUtils
