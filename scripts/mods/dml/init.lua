dofile("scripts/mods/dml/message")
dofile("scripts/mods/dml/hook")

local StateGame = require("scripts/game_states/state_game")
local StateSplash = require("scripts/game_states/game/state_splash")
local GameStateMachine = require("scripts/foundation/utilities/game_state_machine")

-- The loader object that is used during game boot
-- to initialize the modding environment.
local loader = {}

function loader:init(mod_data, boot_gui)
    local ModLoader = dofile("scripts/mods/dml/mod_loader")
    local mod_loader = ModLoader:new(mod_data, boot_gui)
    self._mod_loader = mod_loader
    Managers.mod = mod_loader

    -- The mod loader needs to remain active during game play, to
    -- enable reloads
    Mods.hook.set("DML", StateGame, "update", function(func, dt, ...)
        mod_loader:update(dt)
        return func(dt, ...)
    end)

    -- Skip splash view
    Mods.hook.set("DML", StateSplash, "on_enter", function(func, self, ...)
        local result = func(self, ...)

        self._should_skip = true
        self._continue = true

        return result
    end)

    -- Trigger state change events
    Mods.hook.set("DML", GameStateMachine, "_change_state", function(func, self, ...)
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
    Mods.hook.set("DML", GameStateMachine, "destroy", function(func, self, ...)
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
        mod_loader:remove_gui()
    end

    return done
end

function loader:done()
    return self._mod_loader:all_mods_loaded()
end

return loader
