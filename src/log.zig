const std = @import("std");
const util = @import("util.zig");

var gpa = std.heap.DebugAllocator(.{}){};
const allocator = gpa.allocator();
const max_len: u16 = 256;
var g_id: u32 = 0;
pub const Timestamp = struct {
    date: u64,
    time: u32,
    ms: u16,
    string_stamp: [23]u8,

    pub fn init(date: u64, time: u32, ms: u16, string_stamp: [23]u8) Timestamp {
        return Timestamp{ .date = date, .time = time, .ms = ms, .string_stamp = string_stamp };
    }
};

pub const Level = enum {
    ERROR,
    INFO,
    WARNING,
    TRACE,
    DEBUG,
    pub fn get_string(self: Level) []const u8 {
        switch (self) {
            .ERROR => {
                return "ERROR";
            },
            .INFO => {
                return "INFO";
            },
            .WARNING => {
                return "WARNING";
            },
            .TRACE => {
                return "TRACE";
            },
            .DEBUG => {
                return "DEBUG";
            },
        }
    }
};

const Map = std.static_string_map.StaticStringMap;
const LevelMap = Map(Level).initComptime(.{ .{ "ERROR", Level.ERROR }, .{ "INFO", Level.INFO }, .{ "WARNING", Level.WARNING }, .{ "TRACE", Level.TRACE }, .{ "DEBUG", Level.DEBUG } });

pub const Body = union { small: [max_len]u8, large: []u8 };

pub const RequestLine = struct {
    id: u64,
    timestamp: Timestamp,
    pid: u32,
    level: Level,
    database: []const u8,
    library: []const u8,
    ip_addr: [4]u8,
    body: []const u8,
    http_code: u16,
    sql_queries: u32,
    sql_time: f32,
    python_time: f32,
    extra_lines: std.ArrayList(u64),

    pub fn init(
        id: u64,
        timestamp: Timestamp,
        pid: u32,
        level: Level,
        database: []const u8,
        library: []const u8,
        ip_addr: [4]u8,
        body: []const u8,
        http_code: u16,
        sql_queries: u32,
        sql_time: f32,
        python_time: f32,
    ) RequestLine {
        return RequestLine{
            .id = id,
            .timestamp = timestamp,
            .pid = pid,
            .level = level,
            .database = database,
            .library = library,
            .ip_addr = ip_addr,
            .body = body,
            .http_code = http_code,
            .sql_queries = sql_queries,
            .sql_time = sql_time,
            .python_time = python_time,
            .extra_lines = std.ArrayList(u64).init(allocator),
        };
    }
};

pub const NonRequestLine = struct {
    id: u64,
    timestamp: Timestamp,
    pid: u32,
    level: Level,
    database: []const u8,
    library: []const u8,
    body: []const u8,
    extra_lines: std.ArrayList(u64),

    pub fn init(
        id: u64,
        timestamp: Timestamp,
        pid: u32,
        level: Level,
        database: []const u8,
        library: []const u8,
        body: []const u8,
    ) NonRequestLine {
        return NonRequestLine{
            .id = id,
            .timestamp = timestamp,
            .pid = pid,
            .level = level,
            .database = database,
            .library = library,
            .body = body,
            .extra_lines = std.ArrayList(u64).init(allocator),
        };
    }
};

pub const ExtraLine = struct {
    id: u64,
    line: []const u8,

    pub fn init(id: u64, line: []const u8) ExtraLine {
        return ExtraLine{ .id = id, .line = line };
    }
};

pub const LogLine = union { request_line: RequestLine, non_request_line: NonRequestLine, extra_line: ExtraLine };

const BufSet = std.BufSet;

pub fn is_ip(string: []const u8) bool {
    const nums_and_p = [11]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.' };
    var ip_items = BufSet.init(allocator);
    defer ip_items.deinit();
    if (ip_items.insert(&nums_and_p)) |_| {} else |err| {
        std.debug.print("Something werid is going on with the is_ip function, maybe look into it because it failed. {!}", .{err});
    }

    for (0..string.len) |i| {
        if (ip_items.contains(string[i .. i + 1])) {
            continue;
        } else {
            return false;
        }
    }
    return true;
}

fn _get_body(line: []const u8) [max_len]u8 {
    var iterator = std.mem.splitScalar(u8, line[0..line.len], ' ');

    while (true) {
        const next_word = iterator.next().?;
        if (next_word[next_word.len - 1] == ']') {
            const slice_start: ?usize = iterator.index;

            var body_getter = std.mem.splitScalar(u8, line[slice_start.?..line.len], '"');

            _ = body_getter.next().?;

            const body = body_getter.next().?;

            return body;
        }
    }
}

//this func is big but its just easier that way sry
pub fn parse(line: []const u8) LogLine {
    g_id += 1;
    //we gotta know if there is a log level
    var iterator = std.mem.splitScalar(u8, line[0..line.len], ' ');
    const date = iterator.next().?;
    const time = iterator.next().?;
    const _pid = iterator.next() orelse "0000";
    const log_level = iterator.next() orelse "no level";

    const optional_level = LevelMap.get(log_level);
    var level: Level = undefined;

    if (optional_level == null) {
        const body = line;
        const new_line = ExtraLine.init(g_id, body);
        return LogLine{ .extra_line = new_line };
    } else {
        level = optional_level.?;
    }
    const _date: [8]u8 = date[0..4].* ++ date[5..7].* ++ date[8..10].*;
    const new_date: u64 = std.fmt.parseInt(u64, &_date, 10) catch 0;

    const _time: [6]u8 = time[0..2].* ++ time[3..5].* ++ time[6..8].*;
    const new_time: u32 = std.fmt.parseInt(u32, &_time, 10) catch 0;

    const new_ms: u16 = std.fmt.parseInt(u16, time[9..12], 10) catch 0;

    const string_stamp: [23]u8 = line[0..23];

    const timestamp = Timestamp.init(new_date, new_time, new_ms, string_stamp);

    const pid: u32 = std.fmt.parseInt(u32, _pid[0.._pid.len], 10) catch 0;

    const database = iterator.next().?;

    const library = iterator.next().?;

    const _ip = iterator.peek().?;
    var ip: [4]u8 = undefined;
    //ip presence determines what the rest of the log looks like
    if (is_ip(_ip)) {
        _ = iterator.next().?;

        var ip_iterator = std.mem.splitScalar(u8, _ip[0.._ip.len], '.');

        for (0..ip.len) |i| {
            ip[i] = std.fmt.parseInt(u8, ip_iterator.next().?, 10) catch blk: {
                std.debug.print("Could not parse {s} as int\n", .{ip_iterator.next().?});
                break :blk 0;
            };
        }

        const body = _get_body(line);
        var http_status: u16 = undefined;
        var check = iterator.next().?;
        while (true) {
            if (check[check.len - 1] == '"') {
                const _http_status = iterator.next().?;
                http_status = std.fmt.parseInt(u16, _http_status, 10) catch 0;
                break;
            } else {
                check = iterator.next().?;
            }
        }

        _ = iterator.next().?;
        const _sql_queries = iterator.next().?;
        const sql_queries = std.fmt.parseInt(u32, _sql_queries, 10) catch 0;

        const _sql_time = iterator.next().?;
        const sql_time = std.fmt.parseFloat(f32, _sql_time) catch 0.0;

        const _python_time = iterator.next().?;
        const python_time = std.fmt.parseFloat(f32, _python_time) catch 0.0;

        const log = RequestLine.init(g_id, timestamp, pid, level, database, library, ip, body, http_status, sql_queries, sql_time, python_time);
        return LogLine{ .request_line = log };
    } else {
        //no ip here
        const body = line[iterator.index.?..line.len];

        const log = NonRequestLine.init(g_id, timestamp, pid, level, database, library, body);
        return LogLine{ .non_request_line = log };
    }
}

const expect = std.testing.expect;

test "the whole damn thing" {
    const info_log = "2025-03-25 23:12:22,465 4 INFO test-odoo-db-1122345 werkzeug: 162.17.230.9 - - [25/Mar/2025 23:12:22] \"POST /web/dataset/call_kw/product.template/web_save HTTP/1.0\" 200 - 12 0.005 0.014\n";
    const info_date: u64 = 20250325;
    const info_time: u32 = 231222;
    const info_ms: u16 = 465;
    const info_level = Level.INFO;
    const info_db = "test-odoo-db-1122345";
    const info_library = "werkzeug";
    const info_ip = [4]u8{ 162, 17, 230, 9 };
    const info_http = 200;
    const info_sql = 12;
    const info_sql_time: f32 = 0.005;
    const info_py_time: f32 = 0.014;

    const error_log = "2025-03-25 23:12:14,927 4 ERROR test-odoo-db-1122345 odoo.sql_db: bad query: b'INSERT INTO \"product_packaging\" (\"barcode\", \"company_id\", \"create_date\", \"create_uid\", │\n";
    const error_date: u64 = 20250325;
    const error_time: u32 = 231214;
    const error_ms: u16 = 927;
    const error_level = Level.ERROR;
    const error_db = "test-odoo-db-1122345";
    const error_library = "odoo.sql_db";

    const info_log_obj = parse(info_log);
    try expect(info_date == info_log_obj.timestamp.date);
    try expect(info_time == info_log_obj.timestamp.time);
    try expect(info_ms == info_log_obj.timestamp.ms);
    try expect(info_level == info_log_obj.level);
    try expect(info_db == info_log_obj.database);
    try expect(info_library == info_log_obj.library);
    try expect(info_ip == info_log_obj.ip_addr);
    try expect(info_http == info_log_obj.http_code);
    try expect(info_sql == info_log_obj.sql_queries);
    try expect(info_sql_time == info_log_obj.sql_time);
    try expect(info_py_time == info_log_obj.python_time);

    std.debug.print("\"POST /web/dataset/call_kw/product.template/web_save HTTP/1.0\" = {s}", .{info_log_obj.body});

    const error_log_obj = parse(error_log);
    try expect(error_date == error_log_obj.timestamp.date);
    try expect(error_time == error_log_obj.timestamp.time);
    try expect(error_ms == error_log_obj.timestamp.ms);
    try expect(error_level == error_log_obj.level);
    try expect(error_db == error_log_obj.database);
    try expect(error_library == error_log_obj.library);
}
