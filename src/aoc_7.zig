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
        // print("{any}\n", .{equations.getLast()});
        equation.clearRetainingCapacity();
    }
    const res = part1(equations.items);
    const res2 = part2(equations.items);
    print("{d}\n", .{res});
    print("{d}\n", .{res2});
    for (equations.items) |e| {
        u.allocator.free(e);
    }
}

fn part1(equations: [][]u64) u64 {
    var res: u64 = 0;
    for (equations) |equation| {
        if (isValid(equation[2..], equation[1], equation[0])) {
            res += equation[0];
        }
    }
    return res;
}

fn isValid(equation: []u64, acc: u64, answer: u64) bool {
    if (equation.len == 0) return acc == answer;
    if (acc > answer) return false;
    return isValid(equation[1..], acc + equation[0], answer) or isValid(equation[1..], acc * equation[0], answer);
}

fn part2(equations: [][]u64) u64 {
    _ = equations;
    return 0;
}

