local module = {}
module.name = "Unhide App"
module.version = "1.2"
module.author = "Stepheson Alves"
module.description = "List and restore hidden or minimized applications."

local iconsManager = nil

-- Function to return menu items (Schema)
function module.getMenuItems(options)
    return {
        {
            text = "Unhide App",
            subText = "Show hidden or minimized applications",
            image = hs.image.imageFromPath(hs.configdir .. "/modulespoon/images/unhide_app.png"),
            action = function()
                module.showHiddenAppsMenu()
            end
        }
    }
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Function to list hidden/minimized apps and show a chooser menu
function module.showHiddenAppsMenu()
    local apps = hs.application.runningApplications()
    local menuItems = {}

    for _, app in ipairs(apps) do
        -- Filter: Only show "Standard" applications (kind == 1)
        if app:kind() == 1 then
            local stateTag = nil

            -- Priority 1: App is Hidden (Cmd+H)
            if app:isHidden() then
                stateTag = "[Hid]"
            else
                -- Priority 2: App is not hidden but has ALL windows minimized
                local windows = app:allWindows()
                if #windows > 0 then
                    local allMin = true
                    for _, win in ipairs(windows) do
                        if not win:isMinimized() then
                            allMin = false
                            break
                        end
                    end

                    if allMin then
                        stateTag = "[Min]"
                    end
                end
            end

            if stateTag then
                table.insert(menuItems, {
                    text = string.format("%s %s", stateTag, app:name()),
                    subText = app:bundleID() or "Application",
                    image = hs.image.imageFromAppBundle(app:bundleID()),
                    appObject = app,
                    action = function()
                        module.unhideApp(app)
                    end
                })
            end
        end
    end

    if #menuItems == 0 then
        table.insert(menuItems, {
            text = "No hidden apps found",
            subText = "",
            valid = false
        })
    end

    table.sort(menuItems, function(a, b) return a.text < b.text end)

    local windowGenerator = require("common.window_generator")
    windowGenerator:showMenu(menuItems, "Select App to Restore")
end

-- Function to unhide and activate an app
function module.unhideApp(app)
    -- If Hidden, Unhide
    if app:isHidden() then
        app:unhide()
    end

    -- If Minimized (windows), Unminimize
    for _, win in ipairs(app:allWindows()) do
        if win:isMinimized() then
            win:unminimize()
        end
    end

    app:activate()
end

return module
