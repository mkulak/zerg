const std = @import("std");
const u = @import("utils.zig");
const print = std.debug.print;

pub fn main() anyerror!void {
    defer u.deinit();
    const lines = try u.Lines.fromFile("input4.txt");
    defer lines.deinit();
    try part1(lines.lines);
    try part2(lines.lines);
}

fn part1(lines: []const []const u8) anyerror!void {
    var sum: u32 = 0;
    for (0..lines.len) |y| {
        for (0..lines[y].len) |x| {
            if (lines[y][x] == 'X') {
                for (directions) |dir| {
                    if (check(lines, x, y, dir)) {
                        sum += 1;
                    }
                }
            }
        }
    }
    print("{d}\n", .{sum});
}

fn check(lines: []const []const u8, x: usize, y: usize, dir: XY) bool {
    var nx: isize = @intCast(x);
    var ny: isize = @intCast(y);
    for (0..3) |i| {
        ny += @intCast(dir.y);
        if (ny < 0 or ny >= lines.len) return false;
        nx += @intCast(dir.x);
        if (nx < 0 or nx >= lines[0].len) return false;
        const ch = lines[@intCast(ny)][@intCast(nx)];
        if (ch != "MAS"[i]) {
            return false;
        }
    }
    return true;
}

fn part2(lines: []const []const u8) anyerror!void {
    var sum: u32 = 0;
    for (0..lines.len) |y| {
        for (0..lines[y].len) |x| {
            if (check2(lines, x, y)) {
                sum += 1;
            }
        }
    }
    print("{d}\n", .{sum});
}

fn check2(lines: []const []const u8, x: usize, y: usize) bool {
    if (x < 1 or y < 1 or y > lines.len - 2 or x > lines[y].len - 2 or lines[y][x] != 'A') return false;
    const m1, const s1 = u.minMax(lines[y - 1][x - 1], lines[y + 1][x + 1]);
    const m2, const s2 = u.minMax(lines[y - 1][x + 1], lines[y + 1][x - 1]);
    return m1 == 'M' and m2 == 'M' and s1 == 'S' and s2 == 'S';
}

const XY = struct {
    x: i8,
    y: i8,
    fn new(x: i8, y: i8) XY {
        return XY{ .x = x, .y = y };
    }
};

const directions = [_]XY{
    XY.new(1, 0),
    XY.new(1, 1),
    XY.new(0, 1),
    XY.new(-1, 1),
    XY.new(-1, 0),
    XY.new(-1, -1),
    XY.new(0, -1),
    XY.new(1, -1),
};
