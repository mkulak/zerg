const std = @import("std");
const u = @import("utils.zig");
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();
    var lines = try u.Lines.fromFile("input2.txt");
    defer lines.deinit();
    try part1(lines.lines);
    try part2(lines.lines);
}

fn part1(lines: []const []const u8) !void {
    var safeCount: u32 = 0;
    for (lines) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        var cur = try std.fmt.parseInt(i32, it.next().?, 10);
        var asc: ?bool = null;
        var safe = true;
        while (it.next()) |token| {
            const next = try std.fmt.parseInt(i32, token, 10);
            const dir = next > cur;
            const diff = @abs(next - cur);
            if ((asc orelse dir) != dir or diff < 1 or diff > 3) {
                safe = false;
                break;
            }
            asc = dir;
            cur = next;
        }
        if (safe) {
            safeCount += 1;
        }
    }
    print("{d}\n", .{safeCount});
}

fn check(report: []i32, ignore: usize) bool {
    var cur: ?i32 = null;
    var asc: ?bool = null;
    for (report, 0..) |next, i| {
        if (i == ignore) continue;
        if (cur == null) {
            cur = next;
            continue;
        }
        const dir = next > cur.?;
        const diff = @abs(next - cur.?);
        if ((asc orelse dir) != dir or diff < 1 or diff > 3) {
            return false;
        }
        asc = dir;
        cur = next;
    }
    return true;
}

fn part2(lines: []const []const u8) !void {
    var safeCount: u32 = 0;
    var report = std.ArrayList(i32).init(u.allocator);
    defer report.deinit();

    for (lines) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        while (it.next()) |token| {
            const elem  = try std.fmt.parseInt(i32, token, 10);
            try report.append(elem);
        }
        if (checkWithSkip(report.items)) {
            safeCount += 1;
        }
        report.clearRetainingCapacity();
    }
    print("{d}\n", .{safeCount});
}

fn checkWithSkip(report: []i32) bool {
    for (0..report.len) |i| {
        if (check(report, i)) {
            return true;
        }
    }
    return false;
}

