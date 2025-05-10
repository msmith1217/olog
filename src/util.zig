const std = @import("std");

pub fn add_padding(slice: []const u8, comptime len: usize) [len]u8 {
    var padded_array: [len]u8 = .{0} ** len;

    const copy_len = @min(slice.len, len);
    @memcpy(padded_array[0..copy_len], slice[0..copy_len]);

    return padded_array;
}
