const std = @import("std");

const c = @import("c");

pub const Tray = struct {
    icon: Surface,
    tray: *c.SDL_Tray,

    pub fn create(exitCallback: c.SDL_TrayCallback, callback_user_data: ?*anyopaque) !Tray {
        const icon = try Surface.fromData(@embedFile("assets/icon.png"));
        errdefer icon.deinit();

        const tray = c.SDL_CreateTray(icon.sdl, "eepyxr") orelse return error.FailedToCreateTrayObject;
        errdefer c.SDL_DestroyTray(tray);

        const tray_menu = c.SDL_CreateTrayMenu(tray) orelse return error.FailedToCreateTrayMenu;

        const program_label = c.SDL_InsertTrayEntryAt(
            tray_menu,
            -1,
            "eepyxr",
            c.SDL_TRAYENTRY_BUTTON | c.SDL_TRAYENTRY_DISABLED,
        ) orelse return error.FailedToCreateTrayEntry;
        _ = program_label;

        const exit_button = c.SDL_InsertTrayEntryAt(
            tray_menu,
            -1,
            "Exit", // TODO: make this localizable?
            c.SDL_TRAYENTRY_BUTTON,
        ) orelse return error.FailedToCreateTrayEntry;

        c.SDL_SetTrayEntryCallback(exit_button, exitCallback, callback_user_data);

        return .{
            .icon = icon,
            .tray = tray,
        };
    }

    pub fn deinit(self: Tray) void {
        self.icon.deinit();
        c.SDL_DestroyTray(self.tray);
    }
};

pub const Surface = struct {
    sdl: *c.SDL_Surface,
    data: []const u8,

    pub fn fromData(data: []const u8) !Surface {
        const wanted_channels = 4;

        var width: c_int = undefined;
        var height: c_int = undefined;
        var channels_in_file: c_int = undefined;
        const image_data = c.stbi_load_from_memory(data.ptr, @intCast(data.len), &width, &height, &channels_in_file, wanted_channels) orelse return error.FailedToLoadImage;
        errdefer c.stbi_image_free(image_data);

        const surface = c.SDL_CreateSurfaceFrom(width, height, c.SDL_PIXELFORMAT_RGBA8888, image_data, wanted_channels * width) orelse return error.FailedToCreateSurface;

        return .{ .sdl = surface, .data = image_data[0..@intCast(width * height * wanted_channels)] };
    }

    pub fn deinit(self: Surface) void {
        c.stbi_image_free(@constCast(self.data.ptr)); // SAFETY: this shouldnt actually need mutability...
        c.SDL_DestroySurface(self.sdl);
    }
};
