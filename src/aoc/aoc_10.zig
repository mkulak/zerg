const std = @import("std");
const u = @import("utils.zig");
const XY = u.XY;
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();
    const lines = try u.Lines.fromFile("input10.txt");
    defer lines.deinit();
    var res1: u32 = 0;
    var res2: u32 = 0;
    var i: usize = 0;
    const w = lines.lines[0].len + 1;
    while (std.mem.indexOfScalar(u8, lines.content[i..], '0')) |pos| {
        i += pos;
        const xy = XY.from(usize, i % w, i / w);
        res1 += try calcScore1(lines, xy);
        res2 += try calcScore2(lines, xy);
        i += 1;
    }
    print("{d}\n", .{res1});
    print("{d}\n", .{res2});
}

fn calcScore1(lines: u.Lines, head: XY) !u32 {
    var reached = std.AutoHashMap(XY, void).init(u.allocator);
    defer reached.deinit();
    var queue = std.ArrayList(XY).init(u.allocator);
    defer queue.deinit();
    try queue.append(head);
    while (queue.popOrNull()) |xy| {
        const value = get(lines.lines, xy).?;
        if (value == '9') {
            try reached.put(xy, {});
            continue;
        }
        for (directions) |dir| {
            const next = xy.add(isize, dir.x, dir.y);
            const nextValue = get(lines.lines, next);
            if (nextValue orelse '0' == value + 1) {
                try queue.append(next);
            }
        }
    }
    return reached.count();
}

fn calcScore2(lines: u.Lines, head: XY) !u32 {
    var reached: u32 = 0;
    var queue = std.ArrayList(XY).init(u.allocator);
    defer queue.deinit();
    try queue.append(head);
    while (queue.popOrNull()) |xy| {
        const value = get(lines.lines, xy).?;
        if (value == '9') {
            reached += 1;
            continue;
        }
        for (directions) |dir| {
            const next = xy.add(isize, dir.x, dir.y);
            const nextValue = get(lines.lines, next);
            if (nextValue orelse '0' == value + 1) {
                try queue.append(next);
            }
        }
    }
    return reached;
}

fn get(lines: [][]u8, xy: XY) ?u8 {
    if (xy.y >= 0 and xy.y < lines.len and xy.x >= 0 and xy.x < lines[0].len) {
        return lines[@intCast(xy.y)][@intCast(xy.x)];
    }
    return null;
}

const directions = [_]XY{
    XY.new(1, 0),
    XY.new(0, 1),
    XY.new(-1, 0),
    XY.new(0, -1),
};





