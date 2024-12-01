const std = @import("std");
const print = std.debug.print;

var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
const allocator = gp.allocator();

pub fn main() anyerror!void {
    defer _ = gp.deinit();
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("input1.txt", .{});
    const content = try file.readToEndAlloc(allocator, 1 << 32);
    defer allocator.free(content);
    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    var first = std.ArrayList(u32).init(allocator);
    defer first.deinit();
    var second = std.ArrayList(u32).init(allocator);
    defer second.deinit();
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const e1 = try std.fmt.parseInt(u32, it.next().?, 10);
        const e2 = try std.fmt.parseInt(u32, it.next().?, 10);
        try first.append(e1);
        try second.append(e2);
    }
    try part1(first.items, second.items);
    try part2(first.items, second.items);
}

fn part1(first: []u32, second: []u32) anyerror!void {
    std.mem.sort(u32, first, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, second, {}, comptime std.sort.asc(u32));
    var sum: u64 = 0;
    for (first, second) |a, b| {
        sum += @abs(@as(i64, b) - a);
    }
    print("{d}\n", .{sum});
}

fn part2(first: []u32, second: []u32) anyerror!void {
    var freq = std.AutoHashMap(u32, u32).init(allocator);
    defer freq.deinit();
    for (second) |b| {
        const cur = try freq.getOrPutValue(b, 0);
        cur.value_ptr.* += 1;
    }
    var score: u64 = 0;
    for (first) |a| {
        score += a * (freq.get(a) orelse 0);
    }
    print("{d}\n", .{score});
}
