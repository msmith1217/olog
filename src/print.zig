const std = @import("std");
const log = @import("log.zig");

const stdout = std.io.getStdOut().writer();

pub fn print_log(log: *log.LogLine, print_extra_lines: bool) {
    switch (log) {
        .RequestLog => {
            print_base(*log)
        },
        .NonRequestLog => {
            print_base(*log)
        },
        .ExtraLine => {
            print_base(*log)
            //this shouldn't happen but we gotta account for everything
        },
    }

pub fn print_base(log: *log.LogLine) {
    stdout.print({s}     , {log.timestamp.string_stamp}
