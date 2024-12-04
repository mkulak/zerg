const std = @import("std");
const u = @import("utils.zig");
const XY = u.XY;
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();
    const lines = try u.Lines.fromFile("input4.txt");
    defer lines.deinit();
    try part1(lines.lines);
    try part2(lines.lines);
}

fn part1(lines: []const []const u8) !void {
    var sum: u32 = 0;
    for (0..lines.len) |y| {
        for (0..lines[y].len) |x| {
            if (lines[y][x] == 'X') {
                for (directions) |dir| {
                    if (check1(lines, x, y, dir)) {
                        sum += 1;
                    }
                }
            }
        }
    }
    print("{d}\n", .{sum});
}

fn check1(lines: []const []const u8, x: usize, y: usize, dir: XY) bool {
    const word = [_]u8 {
        get(lines, dir.add(usize, x, y)) orelse 0,
        get(lines, dir.mul(2).add(usize, x, y)) orelse 0,
        get(lines, dir.mul(3).add(usize, x, y)) orelse 0,
    };
    return std.mem.eql(u8, &word, "MAS");
}

fn get(lines: []const []const u8, xy: XY) ?u8 {
    if (xy.y < 0 or xy.y >= lines.len or xy.x < 0 or xy.x >= lines[@intCast(xy.y)].len) return null;
    return lines[@intCast(xy.y)][@intCast(xy.x)];
}

fn part2(lines: []const []const u8) !void {
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
