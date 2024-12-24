const std = @import("std");
const u = @import("utils.zig");
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();

    const lines = try u.Lines.fromFile("input5.txt");
    defer lines.deinit();

    var sumValid: u32 = 0;
    var sumAfterFix: u32 = 0;
    var ordering = std.ArrayList([2]u32).init(u.allocator);
    defer ordering.deinit();
    var updates = std.ArrayList([]const u32).init(u.allocator);
    defer updates.deinit();
    var section1 = true;
    for (lines.lines) |line| {
        if (line.len == 0) {
            section1 = false;
            continue;
        }
        if (section1) {
            var it = std.mem.tokenizeScalar(u8, line, '|');
            const e1 = try std.fmt.parseInt(u32, it.next().?, 10);
            const e2 = try std.fmt.parseInt(u32, it.next().?, 10);
            try ordering.append([2]u32{ e1, e2 });
        } else {
            var it = std.mem.tokenizeScalar(u8, line, ',');
            var update = std.ArrayList(u32).init(u.allocator);
            defer update.deinit();
            while (it.next()) |elem| {
                const num = try std.fmt.parseInt(u32, elem, 10);
                try update.append(num);
            }
            try updates.append(try update.toOwnedSlice());
        }
    }
    for (updates.items) |update| {
        if (valid(update, ordering.items)) {
            sumValid += update[update.len / 2];
        } else {
            const res = try u.allocator.alloc(u32, update.len);
            defer u.allocator.free(res);
            std.mem.copyForwards(u32, res, update);
            fix(res, ordering.items);
            sumAfterFix += res[res.len / 2];
        }
    }
    for (updates.items) |update| {
        u.allocator.free(update);
    }
    print("{d}\n", .{sumValid});
    print("{d}\n", .{sumAfterFix});
}

fn valid(update: []const u32, ordering: []const [2]u32) bool {
    for (0..update.len) |i| {
        for (ordering) |ord| {
            if (ord[1] == update[i] and (std.mem.indexOfScalar(u32, update, ord[0]) orelse 0) > i) {
                return false;
            }
        }
    }
    return true;
}

fn fix(update: []u32, ordering: []const [2]u32) void {
    for (0..update.len) |next| {
        for (next..update.len) |i| {
            const candidate = update[i];
            if (isGood(update, i, ordering)) {
                update[i] = update[next];
                update[next] = candidate;
                break;
            }
        }
    }
}

fn isGood(update: []const u32, i: usize, ordering: []const [2]u32) bool {
    for (ordering) |ord| {
        if (ord[1] == update[i] and in(update, ord[0]) and !in(update[0..i], ord[0])) {
            return false;
        }
    }
    return true;
}

fn in(xs: []const u32, x: u32) bool {
    return std.mem.indexOfScalar(u32, xs, x) != null;
}

