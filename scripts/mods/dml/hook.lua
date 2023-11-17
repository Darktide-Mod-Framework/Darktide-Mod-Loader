-- Hook structure
MODS_HOOKS = MODS_HOOKS or {}
MODS_HOOKS_BY_FILE = MODS_HOOKS_BY_FILE or {}

local function NOOP() end

local item_template = {
    name = "",
    func = NOOP,
    hooks = {},
}

local item_hook_template = {
    name = "",
    func = NOOP,
    enable = false,
    exec = NOOP,
}
local Log = Log

local function print_log_info(mod_name, message)
    Log = Log or rawget(_G, "Log")
    if Log then
        Log._info(mod_name, message)
    else
        print("[" .. mod_name .. "]: " .. message)
    end
end

--
-- Get function by function name
--
local function get_func(obj, func_name)
    return obj[func_name]
end

--
-- Get item by function name
--
local function get_item(obj, func_name)
    -- Find existing item
    for _, item in ipairs(MODS_HOOKS) do
        if item.obj == obj and item.name == func_name then
            return item
        end
    end

    -- Create new item
    local item = table.clone(item_template)
    item.obj = obj
    item.name = func_name
    item.func = get_func(obj, func_name)

    -- Save
    table.insert(MODS_HOOKS, item)

    return item
end

--
-- Get item hook by mod name
--
local function get_item_hook(item, mod_name)
    -- Find existing item
    for _, hook in ipairs(item.hooks) do
        if hook.name == mod_name then
            return hook
        end
    end

    -- Create new item
    local item_hook = table.clone(item_hook_template)
    item_hook.name = mod_name

    -- Save
    table.insert(item.hooks, 1, item_hook)

    return item_hook
end

--
-- If settings are changed the hook itself needs to be updated
--
local function patch()
    for i, item in ipairs(MODS_HOOKS) do
        local last_j = 1
        for j, hook in ipairs(item.hooks) do
            local is_first_hook = j == 1
            if is_first_hook then
                if hook.enable then
                    MODS_HOOKS[i].hooks[j].exec = function(...)
                        local mod_hook = MODS_HOOKS[i]
                        return mod_hook.hooks[j].func(mod_hook.func, ...)
                    end
                else
                    MODS_HOOKS[i].hooks[j].exec = function(...)
                        return MODS_HOOKS[i].func(...)
                    end
                end
            else
                if hook.enable then
                    MODS_HOOKS[i].hooks[j].exec = function(...)
                        local mod_hook = MODS_HOOKS[i]
                        return mod_hook.hooks[j].func(mod_hook.hooks[j - 1].exec, ...)
                    end
                else
                    MODS_HOOKS[i].hooks[j].exec = function(...)
                        return MODS_HOOKS[i].hooks[j - 1].exec(...)
                    end
                end
            end

            last_j = j
        end

        -- Patch orginal function call
        item.obj[item.name] = MODS_HOOKS[i].hooks[last_j].exec
    end
end

--
-- Set hook
--
local function set(mod_name, obj, func_name, hook_func)
    local item = get_item(obj, func_name)
    local item_hook = get_item_hook(item, mod_name)

    print_log_info(mod_name, "Hooking " .. func_name)

    item_hook.enable = true
    item_hook.func = hook_func

    patch()
end

--
-- Set hook on every instance of the given file
--
local function set_on_file(mod_name, filepath, func_name, hook_func)
    -- Add hook create function to list for the file
    MODS_HOOKS_BY_FILE[filepath] = MODS_HOOKS_BY_FILE[filepath] or {}
    local hook_create_func = function(this_filepath, this_index)
        local dynamic_func_name = string.format(
            "Mods.require_store[\"%s\"][%i].%s",
            this_filepath, this_index, func_name
        )
        set(mod_name, dynamic_func_name, hook_func, false)
    end
    table.insert(MODS_HOOKS_BY_FILE[filepath], hook_create_func)

    -- Add the new hook to every instance of the file
    local all_file_instances = Mods.require_store[filepath]
    if all_file_instances then
        for i, item in ipairs(all_file_instances) do
            if item then
                hook_create_func(filepath, i)
            end
        end
    end
end

--
-- Enable/Disable hook
--
local function enable(value, mod_name, func_name)
    for _, item in ipairs(MODS_HOOKS) do
        if item.name == func_name or func_name == nil then
            for _, hook in ipairs(item.hooks) do
                if hook.name == mod_name then
                    hook.enable = value
                    patch()
                end
            end
        end
    end

    return
end

--
-- Enable all hooks on a stored file
--
local function enable_by_file(filepath, store_index)
    local all_file_instances = Mods.require_store[filepath]
    local file_instance = all_file_instances and all_file_instances[store_index]

    local all_file_hooks = MODS_HOOKS_BY_FILE[filepath]

    if all_file_hooks and file_instance then
        for _, hook_create_func in ipairs(all_file_hooks) do
            hook_create_func(filepath, store_index)
        end
    end
end

--
-- Remove hook from chain
--
local function remove(func_name, mod_name)
    for i, item in ipairs(MODS_HOOKS) do
        if item.name == func_name then
            if mod_name ~= nil then
                for j, hook in ipairs(item.hooks) do
                    if hook.name == mod_name then
                        table.remove(item.hooks, j)

                        patch()
                    end
                end
            else
                -- Restore orginal function
                item.obj[item.name] = MODS_HOOKS[i].func

                -- Remove hook function
                table.remove(MODS_HOOKS, i)

                return
            end
        end
    end

    return
end

--
-- Move hook to front of the hook chain
--
local function front(mod_name, func_name)
    for _, item in ipairs(MODS_HOOKS) do
        if item.name == func_name or func_name == nil then
            for i, hook in ipairs(item.hooks) do
                if hook.name == mod_name then
                    local saved_hook = table.clone(hook)
                    table.remove(item.hooks, i)
                    table.insert(item.hooks, saved_hook)

                    patch()
                end
            end
        end
    end

    return
end

Mods.hook = {
    set = set,
    set_on_file = set_on_file,
    enable = enable,
    enable_by_file = enable_by_file,
    remove = remove,
    front = front,
    _get_item = get_item,
    _get_item_hook = get_item_hook,
    _patch = patch,
}
