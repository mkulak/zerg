const std = @import("std");
const u = @import("utils.zig");
const XY = u.XY;
const print = std.debug.print;

pub fn main() !void {
    defer u.deinit();
    // const lines = try u.Lines.fromFile("input9.txt");
    // defer lines.deinit();
    // const mem = try parse(lines.content);
    // defer u.allocator.free(mem);
    // const res = part1(mem, lines.content[0] - '0');
    // print("{d}\n", .{res});
    
    const lines2 = try u.Lines.fromFile("input9.txt");
    defer lines2.deinit();
    const mem2 = try parse(lines2.content);
    defer u.allocator.free(mem2);
    // printMem(mem2, lines2.content[0] - '0');
    const res2 = part2(mem2, lines2.content[0] - '0');
    print("{d}\n", .{res2});
}

fn parse(content: []u8) ![]u16 {
    var size: usize = 0;
    for (content) |c| {
        size += c - '0';
    }
    var mem = try u.allocator.alloc(u16, size);
    var i: usize = 0;
    var nextId: u16 = 0;
    var isFile = true;
    for (content) |c| {
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
    return mem;
}

fn part1(mem: []u16, initial: u8) u64 {
    var a: usize = initial;
    var b: usize = mem.len - 1;
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
    var res: u64 = 0;
    for (0..mem.len) |j| {
        res += j * mem[j];
    }
    return res;
}

fn part2(mem: []u16, initial: u8) u64 {
    var b: usize = mem.len - 1;
    while (true) {
        while (mem[b] == empty and b > 0) {
            b -= 1;
        }
        const fileEndIndex = b;
        while (mem[b] == mem[fileEndIndex] and b > 0) {
            b -= 1;
        }
        if (b == 0) break;
        const fileStartIndex = b + 1;
        const fileLen = fileEndIndex - fileStartIndex + 1;
        const freeIndex = findFreeSpace(mem, initial, fileLen);
        print("file {d}: start={d} len={d}\n", .{mem[fileStartIndex], fileStartIndex, fileLen});
        print("free index={any}\n", .{freeIndex});
        if (freeIndex != null and freeIndex.? < fileStartIndex) {
            const i = freeIndex.?;
            @memset(mem[i..i+fileLen], mem[fileStartIndex]);
            @memset(mem[fileStartIndex..fileStartIndex+fileLen], empty);
            // printMem(mem, initial);
        }
    }
    // printMem(mem, initial);
    var res: u64 = 0;
    for (0..mem.len) |j| {
        res += j * mem[j];
    }
    return res;
}

fn findFreeSpace(mem: []const u16, from: usize, size: usize) ?usize {
    var i = from;
    var curSize: usize = 0;
    var res: ?usize = null;
    while (i < mem.len) : (i += 1) {
        if (mem[i] == empty) {
            if (res == null) {
                res = i;
            }
            curSize += 1;
            if (curSize == size) {
                return res;
            }
        } else {
            curSize = 0;
            res = null;
        }
    }
    return null;
}

fn printMem(mem: []const u16, initial: usize) void {
    for (0..mem.len) |i| {
        const c = if (i < initial) '0' else if (mem[i] == empty) '.' else @as(u8, @intCast(mem[i])) + '0';
        print("{c}", .{c});
    }
    print("\n", .{});
}

const empty: u16 = 0;




