const std = @import("std");

var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
pub const allocator = gp.allocator();

pub fn deinit() void {
    _ = gp.deinit();
}

pub const Lines = struct {
    lines: []const []const u8,
    content: []const u8,

    const Self = @This();

    pub fn fromFile(path: []const u8) !Self {
        const cwd = std.fs.cwd();
        const file = try cwd.openFile(path, .{});
        defer file.close();
        const content = try file.readToEndAlloc(allocator, 1 << 32);
        var tokenized = std.mem.tokenizeScalar(u8, content, '\n');
        var res = std.ArrayList([]const u8).init(allocator);
        while (tokenized.next()) |line| {
            try res.append(line);
        }
        return .{ .lines = try res.toOwnedSlice(), .content = content };
    }

    pub fn deinit(self: *const Self) void {
        allocator.free(self.lines);
        allocator.free(self.content);
    }
};

pub fn minMax(a: u8, b: u8) struct { u8, u8 } {
    return .{ @min(a, b), @max(a, b) };
}

pub const XY = struct {
    x: isize,
    y: isize,

    pub fn new(comptime x: comptime_int, comptime y: comptime_int) XY {
        return XY{ .x = @intCast(x), .y = @intCast(y) };
    }
    pub fn from(comptime T: type, x: T, y: T) XY {
        return XY{ .x = @intCast(x), .y = @intCast(y) };
    }
    pub fn mul(self: XY, comptime k: comptime_int) XY {
        return XY{ .x = self.x * k, .y = self.y * k };
    }
    pub fn add(self: XY, comptime T: type, x: T, y: T) XY {
        return XY{ .x = self.x + @as(isize, @intCast(x)), .y = self.y + @as(isize, @intCast(y)) };
    }
};





