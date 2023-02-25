local require_store = Mods.require_store or {}
Mods.require_store = require_store

local original_require = Mods.original_require or require
Mods.original_require = original_require

local can_insert = function(filepath, new_result)
    local store = require_store[filepath]
    if not store or #store then
        return true
    end

    if store[#store] ~= new_result then
        return true
    end
end

require = function(filepath, ...)
    local result = original_require(filepath, ...)
    if result and type(result) == "table" then
        if can_insert(filepath, result) then
            require_store[filepath] = require_store[filepath] or {}
            local store = require_store[filepath]

            table.insert(store, result)

            --print("[Require] #" .. tostring(#store) .. " of " .. filepath)
            local Mods = Mods
            if Mods.hook then
                Mods.hook.enable_by_file(filepath, #store)
            end
        end
    end

    return result
end
