local systemUtils = {}

---
-- Kill an application by name (effectively restarting it if it's a system service like Finder/Dock)
-- @param appName string The name of the application process to kill (e.g., "Finder", "Dock", "SystemUIServer")
function systemUtils.killApp(appName)
    if not appName or appName == "" then return end

    hs.task.new("/usr/bin/killall", nil, { appName }):start()
    print("systemUtils: Executed killall " .. appName)
end

return systemUtils
