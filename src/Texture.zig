const std = @import("std");

const c = @import("c");

const Texture = @This();

sdl: *c.SDL_GPUTexture,
width: u32,
height: u32,

pub fn load(data: []const u8, gpu_device: *c.SDL_GPUDevice, copy_pass: *c.SDL_GPUCopyPass) !Texture {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels_in_file: c_int = undefined;
    const overlay_texture_image = c.stbi_load_from_memory(data.ptr, data.len, &width, &height, &channels_in_file, 4) orelse return error.FailedToLoadImage;
    defer c.stbi_image_free(overlay_texture_image);

    const image_data = overlay_texture_image[0..@intCast(width * height * 4)];

    // Create our transfer buffer
    const transfer_buffer = c.SDL_CreateGPUTransferBuffer(gpu_device, &.{
        .size = @intCast(image_data.len),
        .usage = c.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
    }) orelse return error.BadTransfreBuffer;
    defer c.SDL_ReleaseGPUTransferBuffer(gpu_device, transfer_buffer);

    // Map our transfer buffer
    const map = c.SDL_MapGPUTransferBuffer(gpu_device, transfer_buffer, false) orelse return error.BadMap;

    // Copy our data
    const map_data: [*]u8 = @ptrCast(@alignCast(map));
    @memcpy(map_data, image_data);

    // Unmap the transfer buffer
    c.SDL_UnmapGPUTransferBuffer(gpu_device, transfer_buffer);

    // Create our final texture
    const overlay_texture = c.SDL_CreateGPUTexture(gpu_device, &.{
        .format = c.SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB,
        .width = @intCast(width),
        .height = @intCast(height),
        .layer_count_or_depth = 1,
        .num_levels = 1,
        .sample_count = c.SDL_GPU_SAMPLECOUNT_1,
        .type = c.SDL_GPU_TEXTURETYPE_2D,
        .usage = c.SDL_GPU_TEXTUREUSAGE_SAMPLER,
    }) orelse return error.BadGpuTexture;
    errdefer c.SDL_ReleaseGPUTexture(gpu_device, overlay_texture);

    // Upload the memory to the texture
    c.SDL_UploadToGPUTexture(copy_pass, &.{
        .transfer_buffer = transfer_buffer,
        .pixels_per_row = @intCast(width),
        .rows_per_layer = @intCast(height),
    }, &.{
        .w = @intCast(width),
        .h = @intCast(height),
        .d = 1,
        .texture = overlay_texture,
    }, false);

    return .{
        .sdl = overlay_texture,
        .width = @intCast(width),
        .height = @intCast(height),
    };
}

pub fn deinit(self: Texture, gpu_device: *c.SDL_GPUDevice) void {
    c.SDL_ReleaseGPUTexture(gpu_device, self.sdl);
}
