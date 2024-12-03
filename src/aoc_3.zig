const std = @import("std");
const print = std.debug.print;
const jstring = @import("jstring");

var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
const allocator = gp.allocator();

pub fn main() anyerror!void {
    defer _ = gp.deinit();
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("input3.txt", .{});
    defer file.close();
    const content = try file.readToEndAlloc(allocator, 1 << 32);
    defer allocator.free(content);
    try part1(content);
    try part2(content);
}

const Mul = struct {
    a: u16,
    b: u16,
};

const Token = union(enum) {
    Do: void,
    Dont: void,
    mul: Mul,
};

const Iterator = struct {
    data: []const u8,
    pos: usize,

    fn parse(mem: []const u8) @This() {
        return .{ .data = mem, .pos = 0};
    }

    fn next(self: *@This()) ?Token {
        while (self.pos < self.data.len) : (self.pos += 1) {
            if (self.parseLiteral("do()")) |_| {
                return Token.Do;
            }
            if (self.parseLiteral("don't()"))  |_| {
                return Token.Dont;
            }
            if (self.parseLiteral("mul("))  |_| {
                const a = self.parseInt() orelse continue;
                self.parseLiteral(",") orelse continue;
                const b = self.parseInt() orelse continue;
                self.parseLiteral(")") orelse continue;
                return Token { .mul = Mul { .a = a, .b = b } };
            }
        }
        return null;
    }

    fn parseLiteral(self: *@This(), value: []const u8) ?void {
        if (self.pos < self.data.len - value.len) {
            const sub = self.data[self.pos..self.pos + value.len];
            if (std.mem.eql(u8, sub, value)) {
                self.pos += value.len;
                return {};
            }
        }
        return null;
    }

    fn parseInt(self: *@This()) ?u16 {
        var res: ?u16 = null;
        for (0..3) |_| {
            if (self.pos >= self.data.len or self.data[self.pos] < '0' or self.data[self.pos] > '9') {
                break;
            }
            res = (res orelse 0) * 10 + self.data[self.pos] - '0';
            self.pos += 1;
        }
        return res;
    }
};

fn part1(mem: []u8) anyerror!void {
    var res: u32 = 0;
    var iterator = Iterator.parse(mem);
    while (iterator.next()) |token| {
        switch (token) {
            .mul => |mul| res += @as(u32, mul.a) * mul.b,
            .Do => {},
            .Dont => {},
        }
    }
    print("{d}\n", .{res});
}

fn part2(mem: []u8) anyerror!void {
    var res: u32 = 0;
    var enabled: bool = true;
    var iterator = Iterator.parse(mem);
    while (iterator.next()) |token| {
        switch (token) {
            .mul => |mul| res += if (enabled) @as(u32, mul.a) * mul.b else 0,
            .Do => enabled = true,
            .Dont => enabled = false,
        }
    }
    print("{d}\n", .{res});
}
