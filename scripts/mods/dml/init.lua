-- The loader object that is used during game boot
-- to initialize the modding environment.
local loader = {}

Mods = {}

function loader:init(libs, mod_data, boot_gui)
    -- The metatable prevents overwriting these
    self._libs = setmetatable({}, { __index = libs })
    Mods.lua = self._libs

    dofile("scripts/mods/dml/message")
    dofile("scripts/mods/dml/require")
    dofile("scripts/mods/dml/class")
    dofile("scripts/mods/dml/hook")

    local ModLoader = dofile("scripts/mods/dml/mod_loader")
    local mod_loader = ModLoader:new(boot_gui, mod_data)
    self._mod_loader = mod_loader

    -- The mod loader needs to remain active during game play, to
    -- enable reloads
    Mods.hook.set("DML", "StateGame.update", function(func, dt, ...)
        mod_loader:update(dt)
        return func(dt, ...)
    end)

    -- Skip splash view
    Mods.hook.set("Base", "StateSplash.on_enter", function(func, self, ...)
        local result = func(self, ...)

        self._should_skip = true
        self._continue = true

        return result
    end)

    -- Trigger state change events
    Mods.hook.set("Base", "GameStateMachine._change_state", function(func, self, ...)
        local old_state = self._state
        local old_state_name = old_state and self:current_state_name()

        if old_state_name then
            mod_loader:on_game_state_changed("exit", old_state_name, old_state)
        end

        local result = func(self, ...)

        local new_state = self._state
        local new_state_name = new_state and self:current_state_name()

        if new_state_name then
            mod_loader:on_game_state_changed("enter", new_state_name, new_state)
        end

        return result
    end)

    -- Trigger ending state change event
    Mods.hook.set("Base", "GameStateMachine.destroy", function(func, self, ...)
        local old_state = self._state
        local old_state_name = old_state and self:current_state_name()

        if old_state_name then
            mod_loader:on_game_state_changed("exit", old_state_name)
        end

        return func(self, ...)
    end)
end

function loader:update(dt)
    local mod_loader = self._mod_loader
    mod_loader:update(dt)

    local done = mod_loader:all_mods_loaded()
    if done then
        mod_loader:_remove_gui()
    end

    return done
end

function loader:done()
    return self._mod_loader:all_mods_loaded()
end

return loader
