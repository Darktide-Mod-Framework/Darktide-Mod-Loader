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

return loader
