const std = @import("std");
const print = std.debug.print;

var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
const allocator = gp.allocator();

const Iterator = std.mem.TokenIterator(u8, .scalar);

pub fn main() anyerror!void {
    defer _ = gp.deinit();
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("input2.txt", .{});
    defer file.close();
    const content = try file.readToEndAlloc(allocator, 1 << 32);
    defer allocator.free(content);
    var lines1 = std.mem.tokenizeScalar(u8, content, '\n');
    var lines2 = std.mem.tokenizeScalar(u8, content, '\n');
    try part1(&lines1);
    try part2(&lines2);
}

fn part1(lines: *Iterator) anyerror!void {
    var safeCount: u32 = 0;
    while (lines.next()) |line| {
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

fn checkWithSkip(report: []i32) bool {
    for (0..report.len) |i| {
        if (check(report, i)) {
            return true;
        }
    }
    return false;
}

fn part2(lines: *Iterator) anyerror!void {
    var safeCount: u32 = 0;
    var report = std.ArrayList(i32).init(allocator);
    defer report.deinit();
    
    while (lines.next()) |line| {
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

