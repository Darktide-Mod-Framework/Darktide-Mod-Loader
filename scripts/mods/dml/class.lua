local original_class = Mods.original_class or class
Mods.original_class = original_class

local _G = _G
local rawget = rawget
local rawset = rawset

-- The `__index` metamethod maps a proper identifier `CLASS.MyClassName` to the
-- stringified version of the key: `"MyClassName"`.
-- This allows using LuaCheck for the stringified class names in hook parameters.
_G.CLASS = _G.CLASS or setmetatable({}, {
    __index = function(_, key)
        return key
    end
})

class = function(class_name, super_name, ...)
    local result = original_class(class_name, super_name, ...)
    if not rawget(_G, class_name) then
        rawset(_G, class_name, result)
    end
    if not rawget(_G.CLASS, class_name) then
        rawset(_G.CLASS, class_name, result)
    end
    return result
end
