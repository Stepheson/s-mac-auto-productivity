-- common/MenuGenerator.lua
-- Generic Menu Generator for Hammerspoon
-- Renders hs.chooser windows based on a standardized schema.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "MenuGenerator"
obj.version = "1.0"
obj.author = "Stepheson Alves"

-- Internal Storage
obj.choosers = {} -- Stack of active choosers for submenus? Or just one?
-- Strategy: We might need a stack to handle "Back" navigation if we want it.
-- For now, let's keep it simple: One active chooser. Opening a submenu replaces the current one.
obj.currentChooser = nil
obj.historyStack = {} -- { { schema = ..., title = ... } }

-- Helper function to process schema items into hs.chooser choices
local function processSchemaToChoices(schemaItems, context)
    local choices = {}
    context.itemsMap = {} -- Map index to original item for retrieval

    local choiceIndex = 1

    for i, item in ipairs(schemaItems) do
        if item.type == "radioGroup" then
            -- Expand Radio Group Items
            if item.items then
                for _, subItem in ipairs(item.items) do
                    local isSelected = (subItem.value == item.currentValue)
                    local icon = isSelected and "(*) " or "( ) "

                    local choice = {
                        text = icon .. subItem.label,
                        subText = subItem.description,
                        index = choiceIndex
                    }

                    table.insert(choices, choice)
                    context.itemsMap[choiceIndex] = subItem -- Store subItem
                    choiceIndex = choiceIndex + 1
                end
            end
        else
            -- Standard 1-to-1 Item
            local choice = {
                text = item.label,
                subText = item.description,
                index = choiceIndex
            }

            if item.type == "toggle" then
                -- Determine current state label
                local idx = item.currentIndex or 1
                if item.states and item.states[idx] then
                    local state = item.states[idx]
                    choice.text = item.label .. ": " .. (state.label or "Unknown")
                    choice.subText = item.description .. " (Click to toggle)"
                end
            elseif item.type == "submenu" then
                choice.text = item.label .. " ▶"
            end

            table.insert(choices, choice)
            context.itemsMap[choiceIndex] = item
            choiceIndex = choiceIndex + 1
        end
    end

    -- Add "Back" button if we are deep in history
    if #context.historyStack > 0 then
        table.insert(choices, {
            text = "⬅ Back",
            subText = "Return to previous menu",
            isBack = true -- Custom flag, numeric index will be nil so itemsMap check won't conflict if we check isBack
        })
    end

    return choices
end

-- Function to handle selection
local function onChoice(choice, context)
    if not choice then return end -- Cancelled/Escaped

    -- We can check the raw table or reconstruct logic
    if choice.isBack then
        -- Pop last history item
        local prev = table.remove(context.historyStack)
        -- Show previous
        obj.show(prev.schema, prev.title, context)
        return
    end

    -- Retrieve original item from map using index
    local item = context.itemsMap[choice.index]
    if not item then return end

    -- Generic Action Execution: If item has an action, execute it.
    -- This covers type="action" and implicit actions (like in radioGroup items)
    if item.action and type(item.action) == "function" then
        item.action()
    end

    -- Type-specific logic (State management, navigation)
    if item.type == "toggle" then
        -- Execute current state action
        local idx = item.currentIndex or 1
        if item.states and item.states[idx] and item.states[idx].action then
            item.states[idx].action()
        end

        -- Advance state index
        local nextIdx = idx + 1
        if nextIdx > #item.states then nextIdx = 1 end
        item.currentIndex = nextIdx

        -- Refresh menu to show new state
        -- Re-process to update map and list
        local choices = processSchemaToChoices(context.currentSchema, context)
        context.chooser:choices(choices)
        context.chooser:refreshChoicesCallback()
        context.chooser:show()
    elseif item.type == "submenu" then
        -- Push current to history
        table.insert(context.historyStack, {
            schema = context.currentSchema,
            title = context.title
        })
        -- Show submenu
        obj.show(item.items, item.label, context)
    end
end

-- Main function to create/show menu
-- @param schema: Table (List of items)
-- @param title: String (Placeholder text)
-- @param context: (Optional) Internal use for state/recursion
function obj.show(schema, title, context)
    -- Initialize context on first call
    if not context then
        context = {
            historyStack = {},
            currentSchema = nil,
            chooser = nil,
            title = nil
        }
        -- reuse existing chooser if possible, or create new?
        -- Let's create one per session to avoid conflicts or create a global one for the module.
        -- Using a module-level variable 'obj.currentChooser' might be safer to ensure only one menu is open at a time.
    end

    -- If there's an existing chooser open, we reuse it or replace it?
    -- hs.chooser needs to be recreated if we want to change callback cleanly or just update choices.
    -- Let's use a single instance pattern for the module.

    if obj.currentChooser then
        obj.currentChooser:hide()
    end

    context.currentSchema = schema
    context.title = title

    obj.currentChooser = hs.chooser.new(function(choice)
        onChoice(choice, context)
    end)

    local choices = processSchemaToChoices(schema, context)

    obj.currentChooser:placeholderText(title or "Menu")
    obj.currentChooser:choices(choices)
    obj.currentChooser:show()

    -- Store chooser in context mainly for refresh access inside callbacks
    context.chooser = obj.currentChooser
end

return obj
