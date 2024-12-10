const std = @import("std");
const u = @import("utils.zig");
const XY = u.XY;
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();
    const lines = try u.Lines.fromFile("input9.txt");
    defer lines.deinit();
    var size: usize = 0;
    for (lines.content) |c| {
        size += c - '0';
    }
    var mem = try u.allocator.alloc(u16, size);
    defer u.allocator.free(mem);
    const empty: u16 = 0;
    var i: usize = 0;
    var nextId: u16 = 0;
    var isFile = true;
    for (lines.content) |c| {
        const value = c  - '0';
        for (0..value) |_| {
            mem[i] = if (isFile) nextId else empty;
            i += 1;
        }
        isFile = !isFile;
        if (isFile) {
            nextId += 1;
        }
    }
    // for (mem) |v| {
    //     const c = if (v == empty) '.' else @as(u8, @intCast(v)) + '0';
    //     print("{c}", .{c});
    // }
    // print("\n", .{});

    var a: usize = lines.content[0] - '0';
    var b: usize = size - 1;
    while (true) {
        while (mem[b] == empty) {
            b -= 1;
        }
        while (mem[a] != empty) {
            a += 1;
        }
        if (a >= b) {
            break;
        }
        mem[a] = mem[b];
        mem[b] = empty;
    }
    // for (mem) |v| {
    //     const c = if (v == empty) '.' else @as(u8, @intCast(v)) + '0';
    //     print("{c}", .{c});
    // }
    // print("\n", .{});
    var res: u64 = 0;
    for (0..size) |j| {
        res += j * mem[j];
    }
    print("{d}\n", .{res});
}



