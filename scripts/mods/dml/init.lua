-- The loader object that is used during game boot
-- to initialize the modding environment.
local loader = {}

Mods = {
    hook = {},
    lua = setmetatable({}, {
        __index = { debug = debug, io = io, ffi = ffi, os = os },
    }),
}

dofile("scripts/mods/dml/require")
dofile("scripts/mods/dml/class")
dofile("scripts/mods/dml/hook")

function loader:init(boot_gui, mod_data)
    local ModLoader = dofile("scripts/mods/dml/mod_loader")
    local mod_loader = ModLoader:init(boot_gui, mod_data)
    self._mod_loader = mod_loader

    Mods.hook.set(StateGame, "update", function(func, dt, ...)
        mod_loader:update(dt)
        return func(dt, ...)
    end)

end

function loader:update(dt)
    self._mod_loader:update(dt)
end

return loader
