-- Codename Engine-style HScript Call event port
-- Psych Engine 1.0.4
-- Install as: mods/custom_events/HScript Call.lua
--
-- Event values:
--   value1 = name of the Lua function to call
--   value2 = optional comma-separated arguments
--
-- Example:
--   Function Name: myFunc
--   Function Parameters: hello,123
--
-- This invokes myFunc("hello", "123") in other loaded Lua scripts.
-- As in the original Codename Engine event, arguments are passed as strings.

local function trim(text)
    return (text:gsub('^%s*(.-)%s*$', '%1'))
end

function onEvent(name, value1, value2)
    if name ~= 'HScript Call' then
        return
    end

    local functionName = trim(tostring(value1 or ''))
    if functionName == '' then
        debugPrint('[HScript Call] Function Name is empty.')
        return
    end

    local args = {}
    local parameterText = tostring(value2 or '')

    -- An empty parameter field means call with zero arguments.
    if parameterText ~= '' then
        for argument in string.gmatch(parameterText .. ',', '(.-),') do
            args[#args + 1] = trim(argument)
        end
    end

    -- Call the named function in other loaded Lua scripts.
    -- ignoreSelf=true prevents this custom event from calling itself.
    callOnLuas(functionName, args, false, true)
end