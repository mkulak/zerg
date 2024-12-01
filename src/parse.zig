const std = @import("std");

const Foo = struct {
    value: u8,
};

const foos: []const []const Foo = parseFoos(
    \\1 2 3
    \\4 5 6
    \\7 8 9
);

fn count(comptime str: []const u8, toFind: u8) usize {
    var res: usize = 0;
    for (str) |ch| {
        if (ch == toFind) {
            res += 1;
        }
    }
    return res;
}

fn parseFoos(comptime input: []const u8) []const []const Foo {
    const linesCount = count(input, '\n') + 1;
    var res: [linesCount][]const Foo = undefined;
    var next = 0;
    var lineStart = 0;
    for (0..input.len + 1) |i| {
        if (i == input.len or input[i] == '\n') {
            res[next] = parseLine(input[lineStart..i]);
            next += 1;
            lineStart = i + 1;
        }
    }
    const c_res = comptime res;
    return c_res[0..];
}

fn parseLine(comptime s:[] const u8) []const Foo {
    // @compileLog("parseLine:", s);
    const size = count(s, ' ') + 1;
    var res: [size]Foo = undefined;
    var i: usize = 0;
    var next = 0;
    while (i < s.len) {
        res[next] = Foo { .value = s[i] - '0' };
        next += 1;
        i += 2;
    }
    const c_res = comptime res;
    return c_res[0..];
}

pub fn main() void {
    for (foos) |line| {
        for (line) |f| {
            std.debug.print("{any} ", .{f.value});
        }
        std.debug.print("\n", .{});
    }
}