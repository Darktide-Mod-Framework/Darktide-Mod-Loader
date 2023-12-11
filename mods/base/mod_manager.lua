local ModManager = class("ModManager")

local Keyboard = Keyboard
local BUTTON_INDEX_R = Keyboard.button_index("r")
local BUTTON_INDEX_LEFT_SHIFT = Keyboard.button_index("left shift")
local BUTTON_INDEX_LEFT_CTRL = Keyboard.button_index("left ctrl")

local LOG_LEVELS = {
	spew = 4,
	info = 3,
	warning = 2,
	error = 1
}

local string_format = string.format
local function printf(f, ...)
	print(string.format(f, ...))
end

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
					copy[deepcopy(orig_key)] = deepcopy(orig_value)
			end
			setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
			copy = orig
	end
	return copy
end

-- Clone the global mod file library to a local table
local _io = deepcopy(Mods.file)

ModManager.init = function (self, boot_gui)
	self._mods = {}
	self._num_mods = nil
	self._state = "not_loaded"
	self._settings = Application.user_setting("mod_manager_settings") or {
		log_level = 1,
		developer_mode = false
	}
	self._chat_print_buffer = {}
	self._reload_data = {}
	self._gui = boot_gui
	self._ui_time = 0
	self._network_callbacks = {}

	Crashify.print_property("realm", "modded")
	
	print("[ModManager] Starting mod manager...")

	self._mod_metadata = {}
	self._state = "scanning"
end

ModManager.developer_mode_enabled = function (self)
	return self._settings.developer_mode
end

ModManager._draw_state_to_gui = function (self, gui, dt)
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

	--Gui.text(gui, status_str .. string.rep(".", (2 * t) % 4), "materials/fonts/arial", 16, nil, Vector3(5, 10, 1))
end

ModManager.remove_gui = function (self)
	self._gui = nil
end

ModManager._has_enabled_mods = function (self)
	return true
end

ModManager._check_reload = function (self)
	return Keyboard.pressed(BUTTON_INDEX_R) and
		Keyboard.button(BUTTON_INDEX_LEFT_SHIFT) + Keyboard.button(BUTTON_INDEX_LEFT_CTRL) == 2
end

ModManager.update = function (self, dt)
	local chat_print_buffer = self._chat_print_buffer
	local num_delayed_prints = #chat_print_buffer

	if num_delayed_prints > 0 and Managers.chat then
		for i = 1, num_delayed_prints, 1 do
			Mods.message.echo(chat_print_buffer[i])

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
		if self._num_mods then
			for i = 1, self._num_mods, 1 do
				local mod = self._mods[i]

				if mod and mod.enabled and not mod.callbacks_disabled then
					self:_run_callback(mod, "update", dt)
				end
			end
		end
		
	elseif self._state == "scanning" then
		self:_build_mod_table()
		self._state = self:_load_mod(1)
		self._ui_time = 0
		
	elseif self._state == "loading" then
		local mod = self._mods[self._mod_load_index]
		local mod_data = mod.data

		mod.state = "running"
		local ok, object = pcall(mod_data.run)

		if not ok then
			self:print("error", "%s", object)
		end

		local name = mod.name
		mod.object = object or {}

		self:_run_callback(mod, "init", self._reload_data[mod.id])
		self:print("info", "%s loaded.", name)

		self._state = self:_load_mod(self._mod_load_index + 1)
	end

	local gui = self._gui

	if gui then
		self:_draw_state_to_gui(gui, dt)
	end

	if old_state ~= self._state then
		self:print("info", "%s -> %s", old_state, self._state)
	end
end

ModManager.all_mods_loaded = function (self)
	return self._state == "done"
end

ModManager.destroy = function (self)
	self:unload_all_mods()
end

ModManager._run_callback = function (self, mod, callback_name, ...)
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
		self:print("error", "Failed to run callback %q for mod %q with id %d. Disabling callbacks until reload.",
				callback_name, mod.name, mod.id)

		mod.callbacks_disabled = true
	end
end

ModManager._build_mod_table = function (self)
	fassert(table.is_empty(self._mods), "Trying to add mods to non-empty mod table")

	-- Get the mods' load order from mod_load_order file
	local mod_load_order = _io.read_content_to_table("mod_load_order", "txt")
	if not mod_load_order then
		print("ERROR executing mod_load_order: " .. tostring(mod_load_order))
		mod_load_order = {}
	end
	
	-- Add DMF to the mod load order
	table.insert(mod_load_order, 1, "dmf")
	
	-- Read the .mod files of given mods and, if everything's fine, add mods' entries to the mods list.
	for i = 1, #mod_load_order do
		local mod_name = mod_load_order[i]
		self._mods[i] = {
			state = "not_loaded",
			callbacks_disabled = false,
			id = i,
			name = mod_name,
			enabled = true,
			handle = mod_name,
			loaded_packages = {}
		}
	end
	
	self._num_mods = #self._mods
end

ModManager._load_mod = function (self, index)
	self._ui_time = 0
	local mods = self._mods
	local mod = mods[index]

	while mod and not mod.enabled do
		index = index + 1
		mod = mods[index]
	end

	if not mod then
		table.clear(self._reload_data)
		return "done"
	end

	local id = mod.id
	local mod_name = mod.name

	self:print("info", "loading mod %s", id)
	Crashify.print_property("modded", true)

	local mod_data = _io.exec_with_return(mod_name, mod_name, "mod")

	if not mod_data then
		self:print("error", "Mod file is invalid or missing. Mod %q with id %d skipped.", mod.name, mod.id)

		mod.enabled = false

		return self:_load_mod(index + 1)
	end
	self:print("spew", "<mod info>\n%s\n</mod info>", mod_data)

	mod.data = mod_data
	mod.name = mod.name or mod_data.NAME or "Mod " .. mod.id
	mod.state = "loading"

	Crashify.print_property(string.format("Mod:%s", mod.name), true)
	print(string.format("[ModManager] Loading mod %s with id %s", mod.name, id))

	self._mod_load_index = index

	return "loading"
end

ModManager.unload_all_mods = function (self)
	if self._state ~= "done" then
		self:print("error", "Mods can't be unloaded, mod state is not \"done\". current: %q", self._state)

		return
	end

	self:print("info", "Unload all mod packages")

	for i = self._num_mods, 1, -1 do
		local mod = self._mods[i]

		if mod and mod.enabled then
			self:unload_mod(i)
		end

		self._mods[i] = nil
	end

	self._num_mods = nil
	self._state = "unloaded"
end

ModManager.unload_mod = function (self, index)
	local mod = self._mods[index]

	if mod then
		self:print("info", "Unloading %q.", mod.name)
		self:_run_callback(mod, "on_unload")

		mod.state = "not_loaded"
	else
		self:print("error", "Mod index %i can't be unloaded, has not been loaded", index)
	end
end

ModManager._reload_mods = function (self)
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
	self._state = "scanning"
	self._reload_requested = false
	
	Mods.message.notify("Mods reloaded.")
end

ModManager.on_game_state_changed = function (self, status, state_name, state_object)
	if self._state == "done" then
		for i = 1, self._num_mods, 1 do
			local mod = self._mods[i]

			if mod and mod.enabled and not mod.callbacks_disabled then
				self:_run_callback(mod, "on_game_state_changed", status, state_name, state_object)
			end
		end
	else
		self:print("warning", "Ignored on_game_state_changed call due to being in state %q", self._state)
	end
end

ModManager._visit = function (self, mod_list, visited, sorted, mod_data)
	self:print("debug", "Visiting mod %q with id %d", mod_data.name, mod_data.id)

	if visited[mod_data] then
		return mod_data.enabled
	end

	if visited[mod_data] ~= nil then
		self:print("error", "Dependency cycle detected at mod %q with id %d", mod_data.name, mod_data.id)

		return false
	end

	visited[mod_data] = false
	local enabled = mod_data.enabled or false

	for i = 1, mod_data.num_children or 0 do
		local child_id = mod_data.children[i]
		local child_index = table.find_by_key(mod_list, "id", child_id)
		local child_mod_data = mod_list[child_index]

		if not child_mod_data then
			self:print("warning", "Mod with id %d not found", child_id)
		elseif not self:_visit(mod_list, visited, sorted, child_mod_data) and enabled then
			self:print("warning", "Disabled mod %q with id %d due to missing dependency %d.",
					mod_data.name, mod_data.id, child_id)

			enabled = false
		end
	end

	mod_data.enabled = enabled
	visited[mod_data] = true
	sorted[#sorted + 1] = mod_data

	return enabled
end

ModManager.print = function (self, level, str, ...)
	local message = string.format("[ModManager][" .. level .. "] " .. tostring(str), ...)
	local log_level = LOG_LEVELS[level] or 99

	if log_level <= 2 then
		print(message)
	end

	if log_level <= self._settings.log_level then
		self._chat_print_buffer[#self._chat_print_buffer + 1] = message
	end
end

ModManager.network_bind = function (self)
	return
end

ModManager.network_unbind = function (self)
	return
end

ModManager.network_is_occupied = function (self)
	return false
end

ModManager.network_send = function (self)
	return
end

ModManager.rpc_mod_user_data = function (self)
	return
end

ModManager.register_network_event_delegate = function (self)
	return
end

ModManager.unregister_network_event_delegate = function (self)
	return
end

ModManager.network_context_created = function (self)
	return
end

return ModManager
