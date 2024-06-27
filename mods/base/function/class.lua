Mods.original_class = Mods.original_class or class

local _G = _G
local rawget = rawget
local rawset = rawset

_G.CLASS = _G.CLASS or setmetatable({}, {
    __index = function(_, key)
        return key
    end
})

class = function(class_name, super_name, ...)
	local result = Mods.original_class(class_name, super_name, ...)
	if not rawget(_G, class_name) then
		rawset(_G, class_name, result)
	end
	if not rawget(_G.CLASS, class_name) then
		rawset(_G.CLASS, class_name, result)
	end
	return result
end