const std = @import("std");

const known_folders = @import("known-folders");

const Config = @This();

/// The amount to dim the display, valid range is 0-1
dim_amount: f32,

pub fn load(arena: std.mem.Allocator) !Config {
    const config_root = try known_folders.getPath(arena, .local_configuration) orelse try std.fs.cwd().realpathAlloc(arena, ".");
    defer arena.free(config_root);

    const config_path = try std.fs.path.join(arena, &.{ config_root, "eepyxr.json" });
    defer arena.free(config_path);

    const config_file = std.fs.openFileAbsolute(config_path, .{}) catch |err| {
        if (err == std.fs.File.OpenError.FileNotFound) {
            const new_file = try std.fs.createFileAbsolute(config_path, .{});

            const default_config: Config = .{
                .dim_amount = 0.85,
            };

            var buffered_writer = std.io.bufferedWriter(new_file.writer());
            try std.json.stringify(default_config, .{ .whitespace = .indent_tab }, buffered_writer.writer());
            try buffered_writer.flush();

            return default_config;
        }

        return err;
    };

    var buffered_reader = std.io.bufferedReader(config_file.reader());

    var json_reader = std.json.reader(arena, buffered_reader.reader());
    const loaded_config = try std.json.parseFromTokenSourceLeaky(Config, arena, &json_reader, .{});

    return loaded_config;
}
