--- === common.manager_mouse ===
---
--- Mouse and cursor interaction utilities.
--- Provides reusable helpers for mouse positioning, screen detection,
--- and window-under-cursor resolution.
---

local M = {}

--- Get current mouse position as an hs.geometry point
-- @return userdata hs.geometry point
function M.getAbsolutePosition()
    return hs.geometry.new(hs.mouse.absolutePosition())
end

--- Get screen containing current cursor position
-- @return userdata hs.screen
function M.getScreenUnderCursor()
    return hs.mouse.getCurrentScreen()
end

--- Resolve visible standard window located under cursor coordinates
-- Iterates hs.window.orderedWindows() to respect macOS window stacking (z-order)
-- @param pos table|userdata|nil Optional coordinates {x, y} or hs.geometry point (defaults to current position)
-- @return userdata|nil hs.window
function M.getWindowUnderCursor(pos)
    local geomPos = hs.geometry.new(pos or hs.mouse.absolutePosition())
    local ordered = hs.window.orderedWindows()

    for _, win in ipairs(ordered) do
        if win:isStandard() and win:isVisible() then
            local frame = win:frame()
            if frame and geomPos:inside(frame) then
                return win
            end
        end
    end

    return nil
end

--- Check if cursor position is inside a specific window
-- @param win userdata hs.window
-- @param pos table|userdata|nil Optional coordinates
-- @return boolean
function M.isCursorInsideWindow(win, pos)
    if not win then return false end
    local geomPos = hs.geometry.new(pos or hs.mouse.absolutePosition())
    local frame = win:frame()
    return frame ~= nil and geomPos:inside(frame)
end

--- Check if cursor is currently over the focused window
-- @param pos table|userdata|nil Optional coordinates
-- @return boolean
function M.isCursorInsideFocusedWindow(pos)
    local focusedWin = hs.window.focusedWindow()
    if not focusedWin then return false end
    return M.isCursorInsideWindow(focusedWin, pos)
end

return M
