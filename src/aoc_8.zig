const std = @import("std");
const u = @import("utils.zig");
const XY = u.XY;
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();
    const lines = try u.Lines.fromFile("input8.txt");
    defer lines.deinit();
    const height = lines.lines.len;
    const width = lines.lines[0].len;
    var map = std.AutoHashMap(u8, std.ArrayList(XY)).init(u.allocator);
    defer map.deinit();
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.deinit();
        }
    }
    for (0..height) |y| {
        for (0..width) |x| {
            const c = lines.lines[y][x];
            if (c == '.') continue;
            const xy = XY.from(usize, x, y);
            try add(&map, c, xy);
        }
    }
    var res2: u64 = 0;
    res2 += 1;
    var antinodes = std.AutoHashMap(XY, void).init(u.allocator);
    defer antinodes.deinit();
    var it = map.iterator();
    while (it.next()) |entry| {
        // print("{c}={any}\n", .{entry.key_ptr.*, entry.value_ptr.*.items});
        try countAntinodes(entry.value_ptr.*.items, width, height, &antinodes);
    }
    print("{d}\n", .{antinodes.count()});
    print("{d}\n", .{res2});

}

fn add(map: *std.AutoHashMap(u8, std.ArrayList(XY)), key: u8, value: XY) !void {
    if (!map.contains(key)) {
        try map.put(key, std.ArrayList(XY).init(u.allocator));
    }
    const list = map.getPtr(key);
    try list.?.*.append(value);
}

fn countAntinodes(antennas: []XY, width: usize, height: usize, map: *std.AutoHashMap(XY, void)) !void {
    for (0..antennas.len) |i| {
        for (i + 1..antennas.len) |j| {
            const a = antennas[i];
            const b = antennas[j];
            const dx = b.x - a.x;
            const dy = b.y - a.y;
            const n1 = b.add(isize, dx, dy);
            const n2 = a.add(isize, -dx, -dy);
            if (valid(n1, width, height)) {
                // print("{d},{d}\n", .{n1.x, n1.y});
                try map.put(n1, {});
            }
            if (valid(n2, width, height)) {
                // print("{d},{d}\n", .{n2.x, n2.y});
                try map.put(n2, {});
            }
        }
    }
}

fn valid(xy: XY, width: usize, height: usize) bool {
    return xy.x >= 0 and xy.x < width and xy.y >= 0 and xy.y < height;
}

fn isValid(equation: []u64, acc: u64, answer: u64, concatEnabled: bool) bool {
    if (equation.len == 0) return acc == answer;
    if (acc > answer) return false;
    return isValid(equation[1..], acc + equation[0], answer, concatEnabled) or
        isValid(equation[1..], acc * equation[0], answer, concatEnabled)
        or (concatEnabled and isValid(equation[1..], concat(acc, equation[0]), answer, true));
}

fn concat(a: u64, b: u64) u64 {
    var res = a;
    var c = b;
    while (c != 0) {
        res *= 10;
        c /= 10;
    }
    return res + b;
}

