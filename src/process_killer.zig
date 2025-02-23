const std = @import("std");

const c = @import("c");

pub fn sigintAllProcessesWithBasename(arena: std.mem.Allocator, exe_name: []const u8) !bool {
    const our_pid = std.os.linux.getpid();

    const search_dir_path = "/proc";

    var search_dir = try std.fs.openDirAbsolute(search_dir_path, .{ .iterate = true });
    defer search_dir.close();

    var killed_any: bool = false;

    var iterator = search_dir.iterate();
    while (try iterator.next()) |dir_to_check| {
        if (dir_to_check.kind != .directory) continue; // skip non directories

        var all_digit: bool = true;
        for (dir_to_check.name) |char| {
            if (!std.ascii.isDigit(char)) {
                all_digit = false;
            }
        }

        // Skip non-pid entries in the folder
        if (!all_digit)
            continue;

        var process_dir = search_dir.openDir(dir_to_check.name, .{}) catch |err| {
            // ignore access/filenotfound errors
            if (err == std.fs.Dir.OpenError.AccessDenied or err == std.fs.Dir.OpenError.FileNotFound)
                continue;

            return err;
        };
        defer process_dir.close();

        const realpath = process_dir.realpathAlloc(arena, "exe") catch |err| {
            // skip shit we dont have access to fuck with
            if (err == std.fs.Dir.RealPathError.AccessDenied or err == std.fs.Dir.RealPathError.FileNotFound) {
                continue;
            }

            return err;
        };
        defer arena.free(realpath);

        const pid = try std.fmt.parseInt(std.posix.pid_t, dir_to_check.name, 10);

        // dont kill self
        if (pid == our_pid)
            continue;

        if (std.mem.eql(u8, std.fs.path.basename(realpath), exe_name)) {
            std.posix.kill(pid, std.posix.SIG.INT) catch |err| {
                // ignore permission denied errors, just continue as if nothing happened
                if (err == std.posix.KillError.PermissionDenied or err == std.posix.KillError.ProcessNotFound)
                    continue;

                return err;
            };

            killed_any = true;
        }
    }

    return killed_any;
}
