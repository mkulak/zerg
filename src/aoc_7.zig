const std = @import("std");
const u = @import("utils.zig");
const XY = u.XY;
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();
    const lines = try u.Lines.fromFile("input7.txt");
    defer lines.deinit();
    var equation = std.ArrayList(u64).init(u.allocator);
    defer equation.deinit();
    var equations = std.ArrayList([]u64).init(u.allocator);
    defer equations.deinit();

    for (lines.lines) |line| {
        var it = std.mem.tokenizeAny(u8, line, ": ");
        while (it.next()) |str| {
            const num = try std.fmt.parseInt(u64, str, 10);
            try equation.append(num);
        }
        try equations.append(try equation.toOwnedSlice());
        equation.clearRetainingCapacity();
    }
    var res1: u64 = 0;
    var res2: u64 = 0;
    for (equations.items) |e| {
        if (isValid(e[2..], e[1], e[0], false)) {
            res1 += e[0];
        }
        if (isValid(e[2..], e[1], e[0], true)) {
            res2 += e[0];
        }
    }
    print("{d}\n", .{res1});
    print("{d}\n", .{res2});
    
    for (equations.items) |e| {
        u.allocator.free(e);
    }
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

