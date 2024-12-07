const std = @import("std");
const u = @import("utils.zig");
const XY = u.XY;
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();
    const lines = try u.Lines.fromFile("input6.txt");
    defer lines.deinit();
    const width = lines.lines[0].len;
    const guardIndex = std.mem.indexOfScalar(u8, lines.content, '^').?;
    const initialGuard = XY.from(usize, guardIndex % (width + 1), guardIndex / (width + 1));
    _ = std.mem.replace(u8, lines.content, "#", &[_]u8{OBSTACLE}, lines.content);
    _ = std.mem.replace(u8, lines.content, ".", &[_]u8{0}, lines.content);
    lines.content[guardIndex] = 0;
    const res = part1(lines, initialGuard);
    print("{d}\n", .{res});
    cleanMap(lines);
    const res2 = part2(lines, initialGuard);
    print("{d}\n", .{res2});
}

fn part1(lines: u.Lines, initialGuard: XY) u32 {
    _ = loops(lines.lines, initialGuard);
    var res: u32 = 0;
    const width = lines.lines[0].len;
    const height = lines.lines.len;
    for (0..height) |y| {
        for (0..width) |x| {
            if (lines.lines[y][x] != OBSTACLE and lines.lines[y][x] != 0) {
                res += 1;
            }
        }
    }
    return res;
}

fn part2(lines: u.Lines, initialGuard: XY) u32 {
    var res: u32 = 0;
    const width = lines.lines[0].len;
    const height = lines.lines.len;
    for (0..height) |y| {
        for (0..width) |x| {
            if (lines.lines[y][x] == 0 and (x != initialGuard.x or y != initialGuard.y)) {
                lines.lines[y][x] = OBSTACLE;
                if (loops(lines.lines, initialGuard)) {
                    res += 1;
                }
                lines.lines[y][x] = 0;
                cleanMap(lines);
            }
        }
    }
    return res;
}

fn cleanMap(lines: u.Lines) void {
    for (0..lines.content.len) |i| {
        lines.content[i] &= 0b1111_0000;
    }
}

fn printMap(lines: u.Lines) void {
    for (lines.lines) |line| {
        for (line) |s| {
            const ch = if (s == OBSTACLE) "#" else if (s & 0b0000_0101 != 0) "-" else if (s & 0b0000_1010 != 0) "|" else ".";
            print("{s} ", .{ch});
        }
        print("\n", .{});
    }
}

fn loops(lines: [][]u8, initialGuard: XY) bool {
    var guard = initialGuard;
    var dir: u3 = 3;
    const width = lines[0].len;
    const height = lines.len;
    mark(lines, guard, dir);
    while (true) {
        const d = directions[dir];
        const nextPos = guard.add(isize, d.x, d.y);
        if (nextPos.x < 0 or nextPos.x >= width or nextPos.y < 0 or nextPos.y >= height) {
            return false;
        }
        const next = lines[@intCast(nextPos.y)][@intCast(nextPos.x)];
        if (next == OBSTACLE) {
            dir = (dir + 1) % @as(u3, @intCast(directions.len));
        } else {
            if (wasHere(lines, nextPos, dir)) {
                return true;
            }
            mark(lines, nextPos, dir);
            guard = nextPos;
        }
    }
}

fn wasHere(lines: []const []const u8, pos: XY, dir: u3) bool {
    return (lines[@intCast(pos.y)][@intCast(pos.x)] & (@as(u8, 1) << dir)) != 0;
}

fn mark(lines: [][]u8, pos: XY, dir: u3) void {
    lines[@intCast(pos.y)][@intCast(pos.x)] |= @as(u8, 1) << dir;
}

const OBSTACLE:u8 = 0b1000_0000;

const directions = [_]XY{
    XY.new(1, 0),
    XY.new(0, 1),
    XY.new(-1, 0),
    XY.new(0, -1),
};
