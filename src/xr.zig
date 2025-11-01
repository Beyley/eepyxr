const std = @import("std");

const c = @import("c");
const options = @import("options");

const log = std.log.scoped(.xr);

const XrResult = enum(c_int) {
    success = 0,
    timeout_expired = 1,
    session_loss_pending = 3,
    event_unavailable = 4,
    space_bounds_unavailable = 7,
    session_not_focused = 8,
    frame_discarded = 9,
    validation_failure = -1,
    runtime_failure = -2,
    out_of_memory = -3,
    api_version_unsupported = -4,
    initialization_failed = -6,
    function_unsupported = -7,
    feature_unsupported = -8,
    extension_not_present = -9,
    limit_reached = -10,
    size_insufficient = -11,
    handle_invalid = -12,
    instance_lost = -13,
    session_running = -14,
    session_not_running = -16,
    session_lost = -17,
    system_invalid = -18,
    path_invalid = -19,
    path_count_exceeded = -20,
    path_format_invalid = -21,
    path_unsupported = -22,
    layer_invalid = -23,
    layer_limit_exceeded = -24,
    swapchain_rect_invalid = -25,
    swapchain_format_unsupported = -26,
    action_type_mismatch = -27,
    session_not_ready = -28,
    session_not_stopping = -29,
    time_invalid = -30,
    reference_space_unsupported = -31,
    file_access_error = -32,
    file_contents_invalid = -33,
    form_factor_unsupported = -34,
    form_factor_unavailable = -35,
    api_layer_not_present = -36,
    call_order_invalid = -37,
    graphics_device_invalid = -38,
    pose_invalid = -39,
    index_out_of_range = -40,
    view_configuration_type_unsupported = -41,
    environment_blend_mode_unsupported = -42,
    name_duplicated = -44,
    name_invalid = -45,
    actionset_not_attached = -46,
    actionsets_already_attached = -47,
    localized_name_duplicated = -48,
    localized_name_invalid = -49,
    graphics_requirements_call_missing = -50,
    runtime_unavailable = -51,
    extension_dependency_not_enabled = -1000710001,
    permission_insufficient = -1000710000,
    android_thread_settings_id_invalid_khr = -1000003000,
    android_thread_settings_failure_khr = -1000003001,
    create_spatial_anchor_failed_msft = -1000039001,
    secondary_view_configuration_type_not_enabled_msft = -1000053000,
    controller_model_key_invalid_msft = -1000055000,
    reprojection_mode_unsupported_msft = -1000066000,
    compute_new_scene_not_completed_msft = -1000097000,
    scene_component_id_invalid_msft = -1000097001,
    scene_component_type_mismatch_msft = -1000097002,
    scene_mesh_buffer_id_invalid_msft = -1000097003,
    scene_compute_feature_incompatible_msft = -1000097004,
    scene_compute_consistency_mismatch_msft = -1000097005,
    display_refresh_rate_unsupported_fb = -1000101000,
    color_space_unsupported_fb = -1000108000,
    space_component_not_supported_fb = -1000113000,
    space_component_not_enabled_fb = -1000113001,
    space_component_status_pending_fb = -1000113002,
    space_component_status_already_set_fb = -1000113003,
    unexpected_state_passthrough_fb = -1000118000,
    feature_already_created_passthrough_fb = -1000118001,
    feature_required_passthrough_fb = -1000118002,
    not_permitted_passthrough_fb = -1000118003,
    insufficient_resources_passthrough_fb = -1000118004,
    unknown_passthrough_fb = -1000118050,
    render_model_key_invalid_fb = -1000119000,
    render_model_unavailable_fb = 1000119020,
    marker_not_tracked_varjo = -1000124000,
    marker_id_invalid_varjo = -1000124001,
    marker_detector_permission_denied_ml = -1000138000,
    marker_detector_locate_failed_ml = -1000138001,
    marker_detector_invalid_data_query_ml = -1000138002,
    marker_detector_invalid_create_info_ml = -1000138003,
    marker_invalid_ml = -1000138004,
    localization_map_incompatible_ml = -1000139000,
    localization_map_unavailable_ml = -1000139001,
    localization_map_fail_ml = -1000139002,
    localization_map_import_export_permission_denied_ml = -1000139003,
    localization_map_permission_denied_ml = -1000139004,
    localization_map_already_exists_ml = -1000139005,
    localization_map_cannot_export_cloud_map_ml = -1000139006,
    spatial_anchors_permission_denied_ml = -1000140000,
    spatial_anchors_not_localized_ml = -1000140001,
    spatial_anchors_out_of_map_bounds_ml = -1000140002,
    spatial_anchors_space_not_locatable_ml = -1000140003,
    spatial_anchors_anchor_not_found_ml = -1000141000,
    spatial_anchor_name_not_found_msft = -1000142001,
    spatial_anchor_name_invalid_msft = -1000142002,
    scene_marker_data_not_string_msft = 1000147000,
    space_mapping_insufficient_fb = -1000169000,
    space_localization_failed_fb = -1000169001,
    space_network_timeout_fb = -1000169002,
    space_network_request_failed_fb = -1000169003,
    space_cloud_storage_disabled_fb = -1000169004,
    passthrough_color_lut_buffer_size_mismatch_meta = -1000266000,
    environment_depth_not_available_meta = 1000291000,
    hint_already_set_qcom = -1000306000,
    not_an_anchor_htc = -1000319000,
    space_not_locatable_ext = -1000429000,
    plane_detection_permission_denied_ext = -1000429001,
    future_pending_ext = -1000469001,
    future_invalid_ext = -1000469002,
    system_notification_permission_denied_ml = -1000473000,
    system_notification_incompatible_sku_ml = -1000473001,
    world_mesh_detector_permission_denied_ml = -1000474000,
    world_mesh_detector_space_not_locatable_ml = -1000474001,
    result_max_enum = 0x7fffffff,
};

pub const Error = @Type(.{ .error_set = blk: {
    const result_values = @typeInfo(XrResult).@"enum".fields;

    var errors: [result_values.len]std.builtin.Type.Error = undefined;

    for (&errors, result_values) |*err, result| {
        err.* = .{ .name = result.name };
    }

    break :blk &errors;
} });

pub fn handleResult(xr_ret: c.XrResult) Error!void {
    const result: XrResult = @enumFromInt(xr_ret);
    if (result == .success) return;

    return switch (result) {
        inline else => |error_result| @field(anyerror, @tagName(error_result)),
    };
}

pub fn boundedStr(comptime len: comptime_int, str: [:0]const u8) ![len]u8 {
    var ret: [len]u8 = @splat(0);

    if (str.len > len) return error.OutOfMemory;
    @memcpy(ret[0..str.len], str);

    return ret;
}

pub fn typeToObjectType(comptime T: type) c.XrObjectType {
    return switch (T) {
        c.XrInstance => c.XR_OBJECT_TYPE_INSTANCE,
        c.XrSpace => c.XR_OBJECT_TYPE_SPACE,
        c.XrActionSet => c.XR_OBJECT_TYPE_ACTION_SET,
        c.XrAction => c.XR_OBJECT_TYPE_ACTION,
        c.XrSwapchain => c.XR_OBJECT_TYPE_SWAPCHAIN,
        else => @compileError("Unknown type " ++ @typeName(T)),
    };
}

pub fn debugMessengerCallback(
    severity: c.XrDebugUtilsMessageSeverityFlagsEXT,
    flags: c.XrDebugUtilsMessageTypeFlagsEXT,
    callback_data: *const c.XrDebugUtilsMessengerCallbackDataEXT,
    user_data: ?*anyopaque,
) callconv(.c) c.XrBool32 {
    _ = user_data;

    const xr_log = std.log.scoped(.xr_debug_messenger);

    var flags_buf: [7 + 10 + 11 + 11 + (3 * 4)]u8 = undefined;
    const flags_str = blk: {
        var writer: std.Io.Writer = .fixed(&flags_buf);

        if (flags & c.XR_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT > 0) writer.writeAll("GENERAL | ") catch unreachable;
        if (flags & c.XR_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT > 0) writer.writeAll("VALIDATION | ") catch unreachable;
        if (flags & c.XR_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT > 0) writer.writeAll("PERFORMANCE | ") catch unreachable;
        if (flags & c.XR_DEBUG_UTILS_MESSAGE_TYPE_CONFORMANCE_BIT_EXT > 0) writer.writeAll("CONFORMANCE | ") catch unreachable;

        // If we wrote some flags, pop the last " | "
        if (@popCount(flags & 0b1111) > 0) writer.undo(3);

        break :blk writer.buffered();
    };

    const format = "[{s}] {s}, {s}, \"{s}\"";
    const args = .{
        flags_str,
        callback_data.functionName,
        callback_data.messageId,
        callback_data.message,
    };

    switch (severity) {
        c.XR_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT => xr_log.debug(format, args),
        c.XR_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT => xr_log.info(format, args),
        c.XR_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT => xr_log.warn(format, args),
        c.XR_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT => xr_log.err(format, args),
        else => xr_log.debug(format, args),
    }

    return c.XR_FALSE;
}

pub const SessionState = enum(c_int) {
    unknown = 0,
    idle = 1,
    ready = 2,
    synchronized = 3,
    visible = 4,
    focused = 5,
    stopping = 6,
    loss_pending = 7,
    exiting = 8,
    _,
};

pub const Extensions = struct {
    EXTX_overlay: ?void = null,

    pub fn numFound(self: Extensions) usize {
        var count: usize = 0;
        const fields = @typeInfo(Extensions).@"struct".fields;
        inline for (fields) |field| {
            if (@field(self, field.name) != null) count += 1;
        }
        return count;
    }

    pub fn toPtrArray(self: Extensions, gpa: std.mem.Allocator) ![][*:0]const u8 {
        const num_extensions = self.numFound();

        const extensions = try gpa.alloc([*:0]const u8, num_extensions);

        var enabled_extensions: usize = 0;
        inline for (@typeInfo(Extensions).@"struct".fields) |field| {
            if (@field(self, field.name) != null) {
                extensions[enabled_extensions] = "XR_" ++ field.name;
                enabled_extensions += 1;
            }
        }

        return extensions;
    }

    pub fn loadFunctionPointers(self: *Extensions, instance: c.XrInstance) !void {
        inline for (@typeInfo(Extensions).@"struct".fields) |extension_field| {
            const ExtensionType = std.meta.Child(extension_field.type);

            if (ExtensionType == void)
                continue;

            const maybe_extension = &@field(self, extension_field.name);

            if (maybe_extension.* != null)
                inline for (@typeInfo(ExtensionType).@"struct".fields) |func_ptr_field| {
                    const func_ptr = &@field(maybe_extension.*.?, func_ptr_field.name);

                    try handleResult(c.xrGetInstanceProcAddr(
                        instance,
                        func_ptr_field.name.ptr,
                        @ptrCast(func_ptr),
                    ));

                    log.debug("Loaded extension function {s}@{x}", .{ func_ptr_field.name, @intFromPtr(func_ptr) });
                };
        }
    }

    pub fn optionallySetObjectNameFormat(
        self: Extensions,
        instance: c.XrInstance,
        object: anytype,
        comptime format: []const u8,
        args: anytype,
    ) !void {
        var name_buf: [64:0]u8 = undefined;

        try self.optionallySetObjectName(instance, object, try std.fmt.bufPrintZ(&name_buf, format, args));
    }

    pub fn optionallySetObjectName(self: Extensions, instance: c.XrInstance, object: anytype, name: [:0]const u8) !void {
        // If we don't have debug tools compiled in, we'll never have the extension available anyway,
        // so let's short circuit this codepath
        if (!options.debug_tools)
            return;

        if (self.EXT_debug_utils) |ext_debug_utils| {
            try ext_debug_utils.setObjectName(instance, object, name);
        }
    }
};

pub const Pfns = struct {
    xrEnumerateInstanceExtensionProperties: *const @TypeOf(c.xrEnumerateInstanceExtensionProperties),
    xrEnumerateApiLayerProperties: *const @TypeOf(c.xrEnumerateApiLayerProperties),
    xrCreateInstance: *const @TypeOf(c.xrCreateInstance),

    pub fn load(get_instance_proc_address: c.PFN_xrGetInstanceProcAddr) Error!Pfns {
        var ret: Pfns = undefined;
        inline for (@typeInfo(Pfns).@"struct".fields) |field| {
            // SAFETY: this is safe
            try handleResult(get_instance_proc_address.?(null, field.name.ptr, @ptrCast(&@field(ret, field.name))));
        }
        return ret;
    }
};

pub fn discoverXrExtensions(gpa: std.mem.Allocator, pfns: Pfns) !Extensions {
    var extension_count: u32 = undefined;
    try handleResult(pfns.xrEnumerateInstanceExtensionProperties(null, 0, &extension_count, null));

    const raw_extensions = try gpa.alloc(c.XrExtensionProperties, extension_count);
    defer gpa.free(raw_extensions);

    for (raw_extensions) |*raw_extension| raw_extension.* = .{ .type = c.XR_TYPE_EXTENSION_PROPERTIES };

    // extension_count may be different at this call!
    try handleResult(pfns.xrEnumerateInstanceExtensionProperties(null, extension_count, &extension_count, raw_extensions.ptr));
    const instance_extensions = raw_extensions[0..extension_count];

    var extensions: Extensions = .{};
    for (instance_extensions) |extension| {
        const extensions_to_check_for = @typeInfo(Extensions).@"struct".fields;
        const extension_name = std.mem.sliceTo(&extension.extensionName, 0);
        log.debug("extension {s} is available", .{extension_name});

        inline for (extensions_to_check_for) |extension_to_check_for| {
            if (std.mem.eql(u8, "XR_" ++ extension_to_check_for.name, extension_name)) {
                @field(extensions, extension_to_check_for.name) = @as(std.meta.Child(extension_to_check_for.type), undefined);
                log.info("Found wanted extension {s}", .{extension_to_check_for.name});
            }
        }
    }

    return extensions;
}

pub fn addOutputToChain(chain: *anyopaque, ptr: *anyopaque) void {
    var last: *c.XrBaseOutStructure = @ptrCast(@alignCast(chain));
    var iter: ?*c.XrBaseOutStructure = last;
    while (iter) |base| {
        last = iter.?;
        iter = base.next;
    }
    last.next = @ptrCast(@alignCast(ptr));
}

pub fn addinputToChain(chain: *anyopaque, ptr: *anyopaque) void {
    var last: *c.XrBaseInStructure = @ptrCast(@alignCast(chain));
    var iter: ?*c.XrBaseInStructure = last;
    while (iter) |base| {
        last = iter.?;
        iter = @constCast(base.next); // SAFETY: we just have to hope...
    }
    last.next = @ptrCast(@alignCast(ptr));
}
