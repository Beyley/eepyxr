const std = @import("std");
const builtin = @import("builtin");

const c = @import("c");

const Config = @import("Config.zig");
const math = @import("math.zig");
const xr = @import("xr.zig");

const log = std.log.scoped(.main);

pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug, .ReleaseSafe => .debug,
        .ReleaseFast, .ReleaseSmall => .info,
    },
};

const Swapchain = struct {
    format: c.SDL_GPUTextureFormat,
    images: [*]*c.SDL_GPUTexture,
    xr: c.XrSwapchain,
    extent: c.XrExtent2Di,

    pub fn deinit(self: Swapchain, gpu_device: *c.SDL_GPUDevice) void {
        // SAFETY: API does not write to these, and is in control of them anyway...
        xr.handleResult(c.SDL_DestroyGPUXRSwapchain(gpu_device, self.xr, @ptrCast(self.images))) catch unreachable;
    }
};

const State = struct {
    gpu_device: *c.SDL_GPUDevice,
    instance: c.XrInstance,
    system_id: c.XrSystemId,
    session: c.XrSession,
    session_state: xr.SessionState,
    frame_arena_impl: std.heap.ArenaAllocator,
    gpa: std.mem.Allocator,
    session_data: ?SessionData,
    swapchain: Swapchain,
    config: Config,
};

const SessionData = struct {
    projection_views: []c.XrCompositionLayerProjectionView,
    views: []c.XrView,

    pub fn deinit(self: SessionData, gpa: std.mem.Allocator) void {
        gpa.free(self.projection_views);
        gpa.free(self.views);
    }
};

var run: bool = true;
const run_ptr: *volatile bool = &run;

pub fn main() !void {
    var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer if (gpa_impl.deinit() == .leak) @panic("MEMORY LEAK FUCKFUCK FCCKNECEKONHSKO");
    const gpa = gpa_impl.allocator();

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) return error.FailedToInitSdl;
    defer c.SDL_Quit();
    log.info("Init SDL", .{});

    const gpu_props = c.SDL_CreateProperties();

    if (!c.SDL_OpenXR_LoadLibrary()) return error.FailedToLoadOpenXRLoader;
    defer c.SDL_OpenXR_UnloadLibrary();
    log.info("Loaded OpenXR", .{});

    const pfns = try xr.Pfns.load(c.SDL_OpenXR_GetXrGetInstanceProcAddr());

    const extensions = try xr.discoverXrExtensions(gpa, pfns);
    log.info("Found wanted extensions", .{});

    if (extensions.EXTX_overlay == null) {
        log.err("MISSING OVERLAY EXTENSION, KILLING SELF IMMEDIATELY", .{});
        return error.MissingOverlayExtension;
    }

    const loaded_extensions = try extensions.toPtrArray(gpa);
    defer gpa.free(loaded_extensions);

    // enable our supported shader formats
    _ = c.SDL_SetBooleanProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_SHADERS_SPIRV_BOOLEAN, true);
    _ = c.SDL_SetBooleanProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_SHADERS_MSL_BOOLEAN, true);
    _ = c.SDL_SetBooleanProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_SHADERS_DXIL_BOOLEAN, true);
    _ = c.SDL_SetBooleanProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_SHADERS_DXBC_BOOLEAN, true);
    // set the app name
    _ = c.SDL_SetStringProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_APPLICATION_NAME, "eepyXR");
    _ = c.SDL_SetNumberProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_APPLICATION_VERSION, 0);
    // set the engine name
    _ = c.SDL_SetStringProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_ENGINE_NAME, "eepyXR");
    _ = c.SDL_SetNumberProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_ENGINE_VERSION, 0x00000001);
    // enable our extensions
    _ = c.SDL_SetPointerProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_EXTENSION_NAMES, @ptrCast(loaded_extensions.ptr));
    _ = c.SDL_SetNumberProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_EXTENSION_COUNT, @intCast(loaded_extensions.len));

    _ = c.SDL_SetBooleanProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_DEBUGMODE_BOOLEAN, builtin.mode == .Debug);
    _ = c.SDL_SetBooleanProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_PREFERLOWPOWER_BOOLEAN, false);

    var instance: c.XrInstance = undefined;
    var system_id: c.XrSystemId = undefined;
    // Enable OpenXR for our GPU device
    _ = c.SDL_SetBooleanProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_ENABLE, true);
    _ = c.SDL_SetPointerProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_INSTANCE_OUT, @ptrCast(&instance));
    _ = c.SDL_SetPointerProperty(gpu_props, c.SDL_PROP_GPU_DEVICE_CREATE_XR_SYSTEM_ID_OUT, @ptrCast(&system_id));

    // Create our GPU device
    const gpu_device: *c.SDL_GPUDevice = c.SDL_CreateGPUDeviceWithProperties(gpu_props) orelse {
        return error.FailedToCreateGPUDevice;
    };
    log.info("Created GPU device", .{});
    defer c.SDL_DestroyGPUDevice(gpu_device);
    defer _ = c.SDL_WaitForGPUIdle(gpu_device); // wait for idle, ignore any error, we're quitting anyway.

    var session: c.XrSession = undefined;

    var session_create_info: c.XrSessionCreateInfo = .{ .type = c.XR_TYPE_SESSION_CREATE_INFO };
    var overlay_session_create_info: c.XrSessionCreateInfoOverlayEXTX = .{
        .type = c.XR_TYPE_SESSION_CREATE_INFO_OVERLAY_EXTX,
        .sessionLayersPlacement = std.math.maxInt(u32), // mark us as the highest priority overlay, since we want to cover *everything*
    };
    xr.addinputToChain(&session_create_info, &overlay_session_create_info);

    try xr.handleResult(c.SDL_CreateGPUXRSession(gpu_device, &session_create_info, &session));
    log.info("Created OpenXR session", .{});
    defer _ = c.xrDestroySession(session);

    var stage_space: c.XrSpace = undefined;
    try xr.handleResult(c.xrCreateReferenceSpace(session, &.{
        .type = c.XR_TYPE_REFERENCE_SPACE_CREATE_INFO,
        .poseInReferenceSpace = .{ .orientation = comptime math.Quaternionf.identity.to() },
        .referenceSpaceType = c.XR_REFERENCE_SPACE_TYPE_STAGE,
    }, &stage_space));

    const config: Config = load_config: {
        var arena: std.heap.ArenaAllocator = .init(gpa);
        defer arena.deinit();

        break :load_config try .load(arena.allocator());
    };

    const swapchain = create_gpu_resources: {
        const cmdbuf = c.SDL_AcquireGPUCommandBuffer(gpu_device) orelse return error.FailedToAcquireGpuCmdBuf;
        errdefer _ = c.SDL_CancelGPUCommandBuffer(cmdbuf);

        const swapchain = try createSwapchain(gpu_device, session, cmdbuf, config);
        errdefer swapchain.deinit(gpu_device);

        if (!c.SDL_SubmitGPUCommandBuffer(cmdbuf)) return error.FailedToSubmitGpuWork;

        break :create_gpu_resources swapchain;
    };
    defer swapchain.deinit(gpu_device);

    var state: State = .{
        .swapchain = swapchain,
        .gpu_device = gpu_device,
        .instance = instance,
        .session = session,
        .session_state = .idle, // session state always defaults to idle
        .system_id = system_id,
        .gpa = gpa,
        .frame_arena_impl = .init(gpa),
        .session_data = null,
        .config = config,
    };
    defer {
        if (state.session_data) |session_data| session_data.deinit(gpa);
        state.frame_arena_impl.deinit();
    }

    const stdin = std.io.getStdIn();
    const stdin_handle = stdin.handle;
    {
        // Set stdin to nonblocking
        var o: std.os.linux.O = @bitCast(@as(u32, @intCast(std.os.linux.fcntl(stdin_handle, std.os.linux.F.GETFL, 0))));
        o.NONBLOCK = true;
        _ = std.os.linux.fcntl(stdin_handle, std.os.linux.F.SETFL, @as(u32, @bitCast(o)));
    }
    const stdin_reader = stdin.reader();

    var frame: usize = 0;
    while (run_ptr.*) {
        defer {
            log.debug("Handled frame {d}", .{frame});
            frame +%= 1;
        }

        defer _ = state.frame_arena_impl.reset(.{ .retain_with_limit = 1024 * 10 });

        var temp_buf: [8]u8 = undefined;
        const read = stdin_reader.read(&temp_buf) catch |err| handle_read_error: {
            if (err == std.fs.File.ReadError.WouldBlock) {
                break :handle_read_error 0;
            }

            return err;
        };

        if (read > 0) {
            switch (state.session_state) {
                .synchronized, .visible, .focused => {
                    try xr.handleResult(c.xrRequestExitSession(session));
                },
                else => {
                    break;
                },
            }
        }

        const frame_arena = state.frame_arena_impl.allocator();

        // Early return if an event says to
        if (!try clearXrEventQueue(&state, frame_arena)) return;

        // sleep 20ms waiting for our session to be ready...
        if (state.session_data == null) {
            std.time.sleep(std.time.ns_per_ms * 20);
            continue;
        }

        const session_data = state.session_data.?;

        var frame_state: c.XrFrameState = .{ .type = c.XR_TYPE_FRAME_STATE };
        try xr.handleResult(c.xrWaitFrame(session, &.{ .type = c.XR_TYPE_FRAME_WAIT_INFO }, &frame_state));

        try xr.handleResult(c.xrBeginFrame(session, &.{ .type = c.XR_TYPE_FRAME_BEGIN_INFO }));

        const layers: []const *const c.XrCompositionLayerBaseHeader = if (frame_state.shouldRender > 0) generate_layers: {
            var view_state: c.XrViewState = .{ .type = c.XR_TYPE_VIEW_STATE };
            var view_count: u32 = undefined;
            try xr.handleResult(c.xrLocateViews(session, &.{
                .type = c.XR_TYPE_VIEW_LOCATE_INFO,
                .displayTime = frame_state.predictedDisplayTime,
                .viewConfigurationType = c.XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO,
                .space = stage_space,
            }, &view_state, @intCast(session_data.views.len), &view_count, session_data.views.ptr));

            const views = session_data.views[0..view_count];
            const projection_views = session_data.projection_views[0..view_count];

            for (views, projection_views) |view, *projection_view| {
                projection_view.* = .{
                    .type = c.XR_TYPE_COMPOSITION_LAYER_PROJECTION_VIEW,
                    .fov = view.fov,
                    .pose = view.pose,
                    .subImage = .{
                        .imageArrayIndex = 0,
                        .swapchain = state.swapchain.xr,
                        .imageRect = .{ .extent = state.swapchain.extent },
                    },
                };
            }

            const layer: c.XrCompositionLayerProjection = .{
                .type = c.XR_TYPE_COMPOSITION_LAYER_PROJECTION,
                .space = stage_space,
                .views = projection_views.ptr,
                .viewCount = @intCast(projection_views.len),
                .layerFlags = c.XR_COMPOSITION_LAYER_BLEND_TEXTURE_SOURCE_ALPHA_BIT,
            };

            break :generate_layers &.{@ptrCast(&layer)};
        } else &.{};

        try xr.handleResult(c.xrEndFrame(session, &.{
            .type = c.XR_TYPE_FRAME_END_INFO,
            .displayTime = frame_state.predictedDisplayTime,
            .environmentBlendMode = c.XR_ENVIRONMENT_BLEND_MODE_OPAQUE,
            .layers = layers.ptr,
            .layerCount = @intCast(layers.len),
        }));
    }
}

fn createSwapchain(gpu_device: *c.SDL_GPUDevice, session: c.XrSession, cmdbuf: *c.SDL_GPUCommandBuffer, config: Config) !Swapchain {
    // this isn't 1x1 to prevent sampling issues, it seems the edges of the swapchain get darker if it's 1x1
    const size = 64;

    const swapchain_create_info: c.XrSwapchainCreateInfo = .{
        .type = c.XR_TYPE_SWAPCHAIN_CREATE_INFO,
        .width = size,
        .height = size,
        .mipCount = 1,
        .sampleCount = 1,
        .faceCount = 1,
        .arraySize = 1,
        .usageFlags = c.XR_SWAPCHAIN_USAGE_COLOR_ATTACHMENT_BIT,
        .createFlags = c.XR_SWAPCHAIN_CREATE_STATIC_IMAGE_BIT,
    };

    // TODO: we need to add an API somewhere in SDL XR to ensure we get a transparent swapchain,
    //       right now we're just relying on the runtime giving us a transparent format early :p
    var texture_format: c.SDL_GPUTextureFormat = undefined;
    var swapchain: c.XrSwapchain = undefined;
    var swapchain_images: [*]*c.SDL_GPUTexture = undefined;
    try xr.handleResult(c.SDL_CreateGPUXRSwapchain(
        gpu_device,
        session,
        &swapchain_create_info,
        &texture_format,
        &swapchain,
        @ptrCast(&swapchain_images), // SAFETY: this API *does* infact work this way, this just isnt expressable in C, so we need to ptrcast
    ));

    var image_index: u32 = undefined;
    try xr.handleResult(c.xrAcquireSwapchainImage(swapchain, &.{ .type = c.XR_TYPE_SWAPCHAIN_IMAGE_ACQUIRE_INFO }, &image_index));

    // NOTE: we can put no timeout, because spec says the runtime *must* eventually give it to us
    try xr.handleResult(c.xrWaitSwapchainImage(swapchain, &.{ .type = c.XR_TYPE_SWAPCHAIN_IMAGE_WAIT_INFO, .timeout = c.XR_INFINITE_DURATION }));

    const swapchain_image = swapchain_images[image_index];

    // Just create an empty render pass to clear the texture
    const render_pass = c.SDL_BeginGPURenderPass(cmdbuf, &.{
        .clear_color = .{ .a = config.dim_amount },
        .load_op = c.SDL_GPU_LOADOP_CLEAR,
        .store_op = c.SDL_GPU_STOREOP_DONT_CARE,
        .texture = swapchain_image,
    }, 1, null) orelse return error.BadRenderPass;
    c.SDL_EndGPURenderPass(render_pass);

    try xr.handleResult(c.xrReleaseSwapchainImage(swapchain, &.{ .type = c.XR_TYPE_SWAPCHAIN_IMAGE_RELEASE_INFO }));

    return .{
        .xr = swapchain,
        .images = swapchain_images,
        .format = texture_format,
        .extent = .{ .width = @intCast(swapchain_create_info.width), .height = @intCast(swapchain_create_info.height) },
    };
}

/// Handles a continuous stream of OpenXR events until none are left to process, returning whether or not to continue the app.
fn clearXrEventQueue(state: *State, arena: std.mem.Allocator) !bool {
    var event: c.XrEventDataBuffer = undefined;

    log.debug("Clearing event queue", .{});
    defer log.debug("Cleared event queue", .{});

    while (true) {
        xr.handleResult(c.xrPollEvent(state.instance, &event)) catch |err| {
            // If we're out of events, break out of the loop
            if (err == xr.Error.event_unavailable)
                return true;

            return err;
        };

        log.debug("Got event with type {d}", .{event.type});

        switch (event.type) {
            c.XR_TYPE_EVENT_DATA_SESSION_STATE_CHANGED => {
                const session_state_changed_event: *const c.XrEventDataSessionStateChanged = @ptrCast(&event);

                state.session_state = @enumFromInt(session_state_changed_event.state);

                log.info("Session state changed to {}", .{state.session_state});
                switch (state.session_state) {
                    .unknown => unreachable,
                    .idle => {},
                    .ready => {
                        // begin the session
                        try xr.handleResult(c.xrBeginSession(state.session, &.{ .type = c.XR_TYPE_SESSION_BEGIN_INFO, .primaryViewConfigurationType = c.XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO }));

                        var view_count: u32 = undefined;
                        try xr.handleResult(c.xrEnumerateViewConfigurationViews(
                            state.instance,
                            state.system_id,
                            c.XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO,
                            0,
                            &view_count,
                            null,
                        ));

                        const views_configuration_views = try arena.alloc(c.XrViewConfigurationView, view_count);
                        defer arena.free(views_configuration_views);
                        @memset(views_configuration_views, .{ .type = c.XR_TYPE_VIEW_CONFIGURATION_VIEW });

                        try xr.handleResult(c.xrEnumerateViewConfigurationViews(
                            state.instance,
                            state.system_id,
                            c.XR_VIEW_CONFIGURATION_TYPE_PRIMARY_STEREO,
                            view_count,
                            &view_count,
                            views_configuration_views.ptr,
                        ));

                        const projection_views: []c.XrCompositionLayerProjectionView = try state.gpa.alloc(c.XrCompositionLayerProjectionView, view_count);
                        errdefer state.gpa.free(projection_views);

                        const views: []c.XrView = try state.gpa.alloc(c.XrView, view_count);
                        errdefer state.gpa.free(views_configuration_views);
                        @memset(views, .{ .type = c.XR_TYPE_VIEW });

                        state.session_data = .{
                            .projection_views = projection_views,
                            .views = views,
                        };
                    },
                    .synchronized => {},
                    .visible => {},
                    .focused => {},
                    .stopping => {
                        try xr.handleResult(c.xrEndSession(state.session));
                    },
                    .exiting, .loss_pending => {
                        run_ptr.* = false;
                        return false;
                    },
                    _ => log.warn("Unhandled session state {d}", .{session_state_changed_event.state}),
                }
            },
            else => {},
        }
    }
}
