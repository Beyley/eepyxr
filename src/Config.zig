const std = @import("std");

const known_folders = @import("known-folders");

const Config = @This();

/// The amount to dim the display, valid range is 0-1
dim_amount: f32 = 0.85,
/// Whether to search for and close the active instance on startup
close_active_instance_on_startup: bool = true,

pub fn load(arena: std.mem.Allocator) !Config {
    const config_root = try known_folders.getPath(arena, .local_configuration) orelse try std.fs.cwd().realpathAlloc(arena, ".");
    defer arena.free(config_root);

    const config_path = try std.fs.path.join(arena, &.{ config_root, "eepyxr.json" });
    defer arena.free(config_path);

    const config_file = std.fs.openFileAbsolute(config_path, .{}) catch |err| {
        if (err == std.fs.File.OpenError.FileNotFound) {
            const new_file = try std.fs.createFileAbsolute(config_path, .{});

            const default_config: Config = .{};

            var config_buffer: [128]u8 = undefined;
            var config_writer = new_file.writer(&config_buffer);
            var config = &config_writer.interface;
            try config.print("{f}", .{std.json.fmt(default_config, .{ .whitespace = .indent_tab })});
            try config.flush();

            return default_config;
        }

        return err;
    };

    var config_buffer: [128]u8 = undefined;
    var config_reader = config_file.reader(&config_buffer);

    const contents = try config_reader.interface.allocRemaining(arena, .limited(2 * 128));
    var json_reader = std.json.Scanner.initCompleteInput(arena, contents);
    const loaded_config = try std.json.parseFromTokenSourceLeaky(Config, arena, &json_reader, .{});

    return loaded_config;
}
