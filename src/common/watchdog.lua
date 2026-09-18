--- === common.watchdog ===
---
--- Generic eventtap and resource watchdog.
--- Monitors event listeners to prevent silent deactivation by macOS latency timeouts.
--- Reusable by any common utility or Spoon.
---

local M = {}
local logger = hs.logger.new("Watchdog", "info")

-- Configuration
M.SWEEP_INTERVAL = 10 -- Sweep check interval in seconds (balanced for 0% CPU and fast recovery)

-- Internal state
local registry = {} -- Array of registered items: { id, resource, shouldBeActive }
local timer = nil
local isMonitoring = false

--- Safely check if a candidate object/module satisfies the watchdog contract
-- @param resource any Candidate object (hs.eventtap userdata or module table)
-- @return boolean isValid, string|nil errorDescription
function M.validate(resource)
    if not resource then
        return false, "Resource is nil"
    end

    -- Case 1: Direct hs.eventtap userdata
    if type(resource) == "userdata" then
        if type(resource.isEnabled) == "function" and type(resource.start) == "function" then
            return true, nil
        end
        return false, "Userdata lacks isEnabled() or start() methods"
    end

    -- Case 2: Module or wrapper table
    if type(resource) == "table" then
        local hasStatus = type(resource.isEnabled) == "function"
            or (resource.listener and type(resource.listener.isEnabled) == "function")
            or (type(resource.getTap) == "function")

        if not hasStatus then
            return false, "Table lacks :isEnabled(), :getTap(), or .listener:isEnabled()"
        end

        local hasRecovery = type(resource.start) == "function"
            or type(resource.enable) == "function"
            or (resource.listener and type(resource.listener.start) == "function")

        if not hasRecovery then
            return false, "Table lacks :start(), :enable(), or .listener:start()"
        end

        return true, nil
    end

    return false, "Expected userdata or table, got " .. type(resource)
end

--- Query the current active/enabled state of a registered resource
-- @param entry table Registry item
-- @return boolean
local function isResourceActive(entry)
    local res = entry.resource
    local statusOk, active = pcall(function()
        if type(res) == "userdata" and type(res.isEnabled) == "function" then
            return res:isEnabled()
        elseif type(res) == "table" then
            if type(res.isEnabled) == "function" then
                return res:isEnabled()
            elseif res.listener and type(res.listener.isEnabled) == "function" then
                return res.listener:isEnabled()
            elseif type(res.getTap) == "function" then
                local tap = res:getTap()
                return tap and tap:isEnabled()
            end
        end
        return false
    end)

    return statusOk and active == true
end

--- Attempt to recover / restart a registered resource
-- @param entry table Registry item
-- @return boolean success
local function recoverResource(entry)
    local res = entry.resource
    local statusOk, _ = pcall(function()
        if type(res) == "userdata" and type(res.start) == "function" then
            res:start()
        elseif type(res) == "table" then
            if type(res.start) == "function" then
                res:start()
            elseif type(res.enable) == "function" then
                res:enable()
            elseif res.listener and type(res.listener.start) == "function" then
                res.listener:start()
            elseif type(res.getTap) == "function" then
                local tap = res:getTap()
                if tap and tap.start then tap:start() end
            end
        end
    end)

    return statusOk
end

--- Register a resource for watchdog monitoring
-- @param resource userdata|table The eventtap or module wrapper
-- @param id string|nil Optional identifier (defaults to resource.name or generated id)
-- @return boolean success
function M.register(resource, id)
    local isValid, err = M.validate(resource)
    if not isValid then
        logger.w(string.format("Registration rejected: %s", tostring(err)))
        return false, err
    end

    local finalId = id or (type(resource) == "table" and resource.name) or ("res_" .. tostring(#registry + 1))

    -- Avoid duplicate registrations for same ID
    for _, existing in ipairs(registry) do
        if existing.id == finalId or existing.resource == resource then
            existing.resource = resource
            existing.shouldBeActive = true
            logger.i(string.format("Updated existing watchdog item '%s'", finalId))
            return true
        end
    end

    table.insert(registry, {
        id = finalId,
        resource = resource,
        shouldBeActive = true
    })

    logger.i(string.format("Registered '%s' for watchdog monitoring", finalId))
    return true
end

--- Unregister a resource from watchdog monitoring
-- @param id string Identifier
-- @return boolean
function M.unregister(id)
    for i, entry in ipairs(registry) do
        if entry.id == id or entry.resource == id then
            table.remove(registry, i)
            logger.i(string.format("Unregistered item '%s'", tostring(id)))
            return true
        end
    end
    return false
end

--- Mark a registered resource as intentionally paused (will not be revived by watchdog)
-- @param id string Identifier
function M.pause(id)
    for _, entry in ipairs(registry) do
        if entry.id == id or entry.resource == id then
            entry.shouldBeActive = false
            return
        end
    end
end

--- Mark a registered resource as active (should be running)
-- @param id string Identifier
function M.resume(id)
    for _, entry in ipairs(registry) do
        if entry.id == id or entry.resource == id then
            entry.shouldBeActive = true
            return
        end
    end
end

--- Perform a single sweep across all registered items
function M.sweep()
    if not isMonitoring then return end

    for _, entry in ipairs(registry) do
        -- Only check and revive resources that are INTENDED to be active
        if entry.shouldBeActive then
            if not isResourceActive(entry) then
                logger.w(string.format("Resource '%s' was unexpectedly disabled by macOS. Reviving...", entry.id))
                recoverResource(entry)
            end
        end
    end
end

--- Start the watchdog sweep timer
-- @return table M
function M.start()
    if isMonitoring then return M end

    isMonitoring = true
    -- Mark all registered resources as shouldBeActive when starting monitoring
    for _, entry in ipairs(registry) do
        entry.shouldBeActive = true
    end

    -- Run an immediate sweep to ensure all items are active
    M.sweep()

    if not timer then
        timer = hs.timer.doEvery(M.SWEEP_INTERVAL, function()
            M.sweep()
        end)
    end

    logger.i("Watchdog monitoring started")
    return M
end

--- Stop the watchdog sweep timer (user-initiated pause)
-- @return table M
function M.stop()
    isMonitoring = false

    if timer then
        timer:stop()
        timer = nil
    end

    -- Mark entries as paused so they are not treated as dropped
    for _, entry in ipairs(registry) do
        entry.shouldBeActive = false
    end

    logger.i("Watchdog monitoring stopped")
    return M
end

--- Check if the watchdog is actively monitoring
-- @return boolean
function M.isMonitoring()
    return isMonitoring
end

--- Get all currently registered items (for inspection and debugging)
-- @return table
function M.getRegistry()
    return registry
end

return M
