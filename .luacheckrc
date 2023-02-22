max_line_length = 120

include_files = {
    "scripts/",
}

ignore = {
    "12.", -- ignore "Setting a read-only global variable/Setting a read-only field of a global variable."
    "542", -- disable warnings for empty if branches. These are useful sometime and easy to notice otherwise.
    "212/self", -- Disable unused self warnings.
    "432/self", -- Allow shadowing `self`, often happens when creating hooks in functions
}

std = "+DT+DML"

stds["DML"] = {
    read_globals = {
        "MODS_HOOKS", "MODS_HOOKS_BY_FILE", "Log",
        Mods = { fields = {
            lua = { fields = { "debug", "io", "ffi", "os" }},
            hook = { fields = {
                "set",
                "set_on_file",
                "enable",
                "enable_by_file",
                "remove",
                "front",
                "_get_item",
                "_get_item_hook",
                "_patch",
            }},
            message = { fields = { "echo", "notify" }},
            "original_require",
            "require_store",
            "original_class",
        }},
    },
}

stds["DT"] = {
    read_globals = {
        string = { fields = { "split" }},
        table = { fields = {
            "merge", "table_to_array", "mirror_table", "tostring", "is_empty", "array_to_table", "reverse", "shuffle",
            "merge_recursive", "unpack_map", "remove_unordered_items", "append", "mirror_array_inplace", "size", "dump",
            "clear_array", "append_varargs", "find", "for_each", "crop", "mirror_array", "set", "create_copy", "clone",
            "contains", "add_meta_logging", "table_as_sorted_string_arrays", "clone_instance", "max", "clear", "find_by_key",
        }},
        math = { fields = {
            "ease_exp", "lerp", "polar_to_cartesian", "smoothstep", "easeCubic", "round", "point_is_inside_2d_triangle",
            "radians_to_degrees", "circular_to_square_coordinates", "uuid", "easeInCubic", "round_with_precision",
            "clamp", "get_uniformly_random_point_inside_sector", "angle_lerp", "ease_out_exp", "rand_normal",
            "bounce", "point_is_inside_2d_box", "catmullrom", "clamp_direction", "ease_in_exp", "random_seed",
            "sign", "degrees_to_radians", "sirp", "ease_pulse", "cartesian_to_polar", "ease_out_quad",
            "easeOutCubic", "radian_lerp", "auto_lerp", "rand_utf8_string", "point_is_inside_oobb",
        }},
        Managers = { fields = {
            "mod", "event", "chat"
        }},
        "Crashify","Keyboard","Mouse","Application","Color","Quarternion","Vector3","Vector2","RESOLUTION_LOOKUP",
        "ModManager", "Utf8", "StateGame", "ResourcePackage", "class", "Gui", "fassert", "printf", "__print", "ffi",
        "class",
    },
}

