require("scripts/mods/dml/message")
require("scripts/mods/dml/hook")

-- The loader object that is used during game boot
-- to initialize the modding environment.
local DML = {}

function DML.create_loader(mod_data)
    local StateGame = require("scripts/game_states/state_game")
    local StateSplash = require("scripts/game_states/game/state_splash")
    local GameStateMachine = require("scripts/foundation/utilities/game_state_machine")

    local ModLoader = dofile("scripts/mods/dml/mod_loader")
    local mod_loader = ModLoader:new(mod_data)

    -- The mod loader needs to remain active during game play, to
    -- enable reloads
    Mods.hook.set("DML", StateGame, "update", function(func, self, dt, ...)
        mod_loader:update(dt)
        return func(self, dt, ...)
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

    return mod_loader
end

return DML
