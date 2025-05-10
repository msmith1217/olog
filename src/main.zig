const std = @import("std");
const log = @import("log.zig");
var gpa = std.heap.DebugAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();

    const argError = error{
        TooManyArguments,
        InvalidArgumentUsed,
    };
    _ = argsIterator.next().?;
    const options = argsIterator.next() orelse "default";
    _ = options;
    const filepath = argsIterator.next() orelse "/Users/macsmith/Downloads/odoo.log.2025-03-25";
    //FIX THIS LATER, would be cool to search /Downloads for log files

    if (argsIterator.next()) |_| {
        std.debug.print("Too many command line arguments, two are expected", .{});
        return argError.TooManyArguments;
    }

    const cwd = std.fs.cwd();
    //Todo support multiple files
    //std.fmt.comptimePrint("{s}", .{filepath});
    const file = try cwd.openFile(filepath, .{ .mode = .read_only });
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var reader = std.io.bufferedReader(file.reader());
    var fbs = std.io.fixedBufferStream(&buffer);

    var log_lines = try std.ArrayList(log.LogLine).initCapacity(allocator, 10000);
    //var extra_lines = try std.ArrayList(log.ExtraLine).initCapacity(allocator, 1000);

    const file_size = try file.getEndPos();
    var bytes_read: u64 = 0;
    while (true) {
        fbs.reset();
        try reader.reader().streamUntilDelimiter(fbs.writer(), '\n', reader.buf.len);

        const line = fbs.getWritten();
        bytes_read += (fbs.getWritten().len + 1);
        const log_line = log.parse(line);

        try log_lines.append(log_line);

        if (bytes_read >= file_size) {
            break;
        }
    }
}
