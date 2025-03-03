const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const src = b.path("src");

    const sdl_include = b.dependency("SDL", .{}).path("include");
    const stb = b.dependency("stb", .{}).path(".");

    const known_folders_dep = b.dependency("known-folders", .{ .target = target, .optimize = optimize });
    const known_folders_mod = known_folders_dep.module("known-folders");

    const translate_c = b.addTranslateC(.{
        .link_libc = true,
        .optimize = optimize,
        .target = target,
        .root_source_file = src.path(b, "c.h"),
    });
    translate_c.addIncludePath(sdl_include);
    translate_c.addIncludePath(stb);

    const translate_c_mod = translate_c.createModule();

    const exe_mod = b.createModule(.{
        .root_source_file = src.path(b, "main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "c",
                .module = translate_c_mod,
            },
            .{
                .name = "known-folders",
                .module = known_folders_mod,
            },
        },
        .link_libc = true,
    });
    exe_mod.linkSystemLibrary("SDL3", .{});
    exe_mod.linkSystemLibrary("openxr_loader", .{});

    exe_mod.addIncludePath(stb);
    exe_mod.addCSourceFile(.{ .file = src.path(b, "c.c") });

    exe_mod.addAnonymousImport("assets/icon.png", .{ .root_source_file = b.path("assets/icon.png") });
    exe_mod.addAnonymousImport("assets/grid.png", .{ .root_source_file = b.path("assets/grid.png") });
    // exe_mod.addAnonymousImport("assets/icon.png", .{ .root_source_file = b.path("assets/half-pipe.png") });

    const exe = b.addExecutable(.{
        .name = "eepyxr",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);
}
