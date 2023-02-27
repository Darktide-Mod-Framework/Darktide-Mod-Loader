Mods.require_store = Mods.require_store or {}
Mods.original_require = Mods.original_require or require

local can_insert = function(filepath, new_result)
	local store = Mods.require_store[filepath]
	if not store or #store == 0 then
		return true
	end
	
	if store[#store] ~= new_result then
		return true
	end
end

require = function(filepath, ...)
	local Mods = Mods

	local result = Mods.original_require(filepath, ...)
	if result and type(result) == "table" then

		if can_insert(filepath, result) then
			Mods.require_store[filepath] = Mods.require_store[filepath] or {}
			local store = Mods.require_store[filepath]

			table.insert(store, result)

			--print("[Require] #" .. tostring(#store) .. " of " .. filepath)
			if Mods.hook then
				Mods.hook.enable_by_file(filepath, #store)
			end
		end
	end
	
	return result
end