-- Copyright on this file is owned by Fatshark.
-- It is extracted, used and modified with permission only for
-- the purpose of loading mods within Warhammer 40,000: Darktide.
local ModLoader = class("ModLoader")

local LOG_LEVELS = {
    spew = 4,
    info = 3,
    warning = 2,
    error = 1
}
local DEFAULT_SETTINGS = {
    log_level = LOG_LEVELS.error,
    developer_mode = false
}

local Keyboard = Keyboard
local BUTTON_INDEX_R = Keyboard.button_index("r")
local BUTTON_INDEX_LEFT_SHIFT = Keyboard.button_index("left shift")
local BUTTON_INDEX_LEFT_CTRL = Keyboard.button_index("left ctrl")

ModLoader.init = function(self, boot_gui, mod_data)
    self._mod_data = mod_data
    self._gui = boot_gui

    self._settings = Application.user_setting("mod_settings") or DEFAULT_SETTINGS

    self._mods = {}
    self._num_mods = nil
    self._chat_print_buffer = {}
    self._reload_data = {}
    self._ui_time = 0

    if Crashify then
      Crashify.print_property("modded", true)
    end

    self._state = "scanning"
end

ModLoader.developer_mode_enabled = function(self)
    return self._settings.developer_mode
end

ModLoader._draw_state_to_gui = function(self, gui, dt)
    local state = self._state
    local t = self._ui_time + dt
    self._ui_time = t
    local status_str = "Loading mods"

    if state == "scanning" then
        status_str = "Scanning for mods"
    elseif state == "loading" then
        local mod = self._mods[self._mod_load_index]
        status_str = string.format("Loading mod %q", mod.name)
    end

    Gui.text(gui, status_str .. string.rep(".", (2 * t) % 4), "materials/fonts/arial", 16, nil, Vector3(5, 10, 1))
end

ModLoader.remove_gui = function(self)
    self._gui = nil
end

ModLoader._check_reload = function()
    return Keyboard.pressed(BUTTON_INDEX_R) and
        Keyboard.button(BUTTON_INDEX_LEFT_SHIFT) +
        Keyboard.button(BUTTON_INDEX_LEFT_CTRL) == 2
end

ModLoader.update = function(self, dt)
    local chat_print_buffer = self._chat_print_buffer
    local num_delayed_prints = #chat_print_buffer

    if num_delayed_prints > 0 and Managers.chat then
        for i = 1, num_delayed_prints, 1 do
            -- TODO: Use new chat system
            -- Managers.chat:add_local_system_message(1, chat_print_buffer[i], true)

            chat_print_buffer[i] = nil
        end
    end

    local old_state = self._state

    if self._settings.developer_mode and self:_check_reload() then
        self._reload_requested = true
    end

    if self._reload_requested and self._state == "done" then
        self:_reload_mods()
    end

    if self._state == "done" then
        for i = 1, self._num_mods, 1 do
            local mod = self._mods[i]

            if mod and not mod.callbacks_disabled then
                self:_run_callback(mod, "update", dt)
            end
        end
    elseif self._state == "scanning" then
        self:_build_mod_table()

        self._state = self:_load_mod(1)
        self._ui_time = 0
    elseif self._state == "loading" then
        local handle = self._loading_resource_handle

        if ResourcePackage.has_loaded(handle) then
            ResourcePackage.flush(handle)

            local mod = self._mods[self._mod_load_index]
            local next_index = mod.package_index + 1
            local mod_data = mod.data

            if next_index > #mod_data.packages then
                mod.state = "running"
                local ok, object = pcall(mod_data.run)

                if not ok then self:print("error", "%s", object) end

                local name = mod.name
                mod.object = object or {}

                self:print("info", "%s loaded.", name)

                self._state = self:_load_mod(self._mod_load_index + 1)
            else
                self:_load_package(mod, next_index)
            end
        end
    end

    local gui = self._gui

    if gui then
      self:_draw_state_to_gui(gui, dt)
    end

    if old_state ~= self._state then
        self:print("info", "%s -> %s", old_state, self._state)
    end
end

ModLoader.all_mods_loaded = function(self)
    return self._state == "done"
end

ModLoader.destroy = function(self)
    for i = 1, self._num_mods, 1 do
        local mod = self._mods[i]

        if mod and not mod.callbacks_disabled then
            self:_run_callback(mod, "on_destroy")
        end
    end

    self:unload_all_mods()
end

ModLoader._run_callback = function (self, mod, callback_name, ...)
    local object = mod.object
    local cb = object[callback_name]

    if not cb then
        return
    end

    local success, val = pcall(cb, object, ...)

    if success then
        return val
    else
        self:print("error", "%s", val or "[unknown error]")
        self:print("error", "Failed to run callback %q for mod %q with id %d. Disabling callbacks until reload.", callback_name, mod.name, mod.id)

        mod.callbacks_disabled = true
    end
end

ModLoader._start_scan = function(self)
    self:print("info", "Starting mod scan")
    self._state = "scanning"
end

ModLoader._build_mod_table = function(self)
    fassert(table.is_empty(self._mods), "Trying to add mods to non-empty mod table")

    for i, mod_data in ipairs(self._mod_data) do
        printf("[ModLoader] mods[%d] = id=%q | name=%q", i, mod_data.id, mod_data.name)

        self._mods[i] = {
            id = mod_data.id,
            state = "not_loaded",
            callbacks_disabled = false,
            name = mod_data.name,
            loaded_packages = {},
            packages = mod_data.packages,
        }
    end

    self._num_mods = #self._mods

    self:print("info", "Found %i mods", #self._mods)
end

ModLoader._load_mod = function(self, index)
    self._ui_time = 0
    local mods = self._mods
    local mod = mods[index]

    if not mod then
        table.clear(self._reload_data)

        return "done"
    end

    self:print("info", "loading mod %i", mod.id)

    mod.state = "loading"

    Crashify.print_property(string.format("Mod:%i:%s", mod.id, mod.name), true)

    self._mod_load_index = index

    self:_load_package(mod, 1)

    return "loading"
end

ModLoader._load_package = function(self, mod, index)
    mod.package_index = index
    local package_name = mod.packages[index]

    if not package_name then
        return
    end

    self:print("info", "loading package %q", package_name)

    local resource_handle = Application.resource_package(package_name)
    self._loading_resource_handle = resource_handle

    ResourcePackage.load(resource_handle)

    mod.loaded_packages[#mod.loaded_packages + 1] = resource_handle
end

ModLoader.unload_all_mods = function(self)
    if self._state ~= "done" then
        self:print("error", "Mods can't be unloaded, mod state is not \"done\". current: %q", self._state)

        return
    end

    self:print("info", "Unload all mod packages")

    for i = self._num_mods, 1, -1 do
        local mod = self._mods[i]

        if mod then
            self:unload_mod(i)
        end

        self._mods[i] = nil
    end

    self._num_mods = nil
    self._state = "unloaded"
end

ModLoader.unload_mod = function(self, index)
    local mod = self._mods[index]

    if mod then
        self:print("info", "Unloading %q.", mod.name)

        for _, handle in ipairs(mod.loaded_packages) do
            ResourcePackage.unload(handle)
            Application.release_resource_package(handle)
        end

        mod.state = "not_loaded"
    else
        self:print("error", "Mod index %i can't be unloaded, has not been loaded", index)
    end
end

ModLoader._reload_mods = function(self)
    self:print("info", "reloading mods")

    for i = 1, self._num_mods, 1 do
        local mod = self._mods[i]

        if mod and mod.state == "running" then
            self:print("info", "reloading %s", mod.name)

            self._reload_data[mod.id] = self:_run_callback(mod, "on_reload")
        else
            self:print("info", "not reloading mod, state: %s", mod.state)
        end
    end

    self:unload_all_mods()
    self:_start_scan()

    self._reload_requested = false
end

ModLoader.on_game_state_changed = function(self, status, state_name, state_object)
    if self._state == "done" then
		for i = 1, self._num_mods, 1 do
			local mod = self._mods[i]

			if mod and not mod.callbacks_disabled then
				self:_run_callback(mod, "on_game_state_changed", status, state_name, state_object)
			end
		end
    else
        self:print("warning", "Ignored on_game_state_changed call due to being in state %q", self._state)
    end
end

ModLoader.print = function(self, level, str, ...)
    local message = string.format("[ModLoader][" .. level .. "] " .. str, ...)
    local log_level = LOG_LEVELS[level] or 99

    if log_level <= 2 then
        print(message)
    end

    if log_level <= self._settings.log_level then
        self._chat_print_buffer[#self._chat_print_buffer + 1] = message
    end
end

return ModLoader