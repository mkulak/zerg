const std = @import("std");
const print = std.debug.print;

var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
const allocator = gp.allocator();

pub fn main() anyerror!void {
    defer _ = gp.deinit();
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("input2.txt", .{});
    defer file.close();
    const content = try file.readToEndAlloc(allocator, 1 << 32);
    defer allocator.free(content);
    var lines = std.mem.tokenizeScalar(u8, content, '\n');

    var safeCount: u32 = 0;
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        var cur = try std.fmt.parseInt(i32, it.next().?, 10);
        var asc: ?bool = null;
        var safe = true;
        while (it.next()) |token| {
            const next = try std.fmt.parseInt(i32, token, 10);
            const dir = next > cur;
            const diff = @abs(next - cur);
            if ((asc orelse dir) != dir or diff < 1 or diff > 3) {
                safe = false;
                break;
            }
            asc = dir;
            cur = next;
        }
        if (safe) {
            safeCount += 1;
        }
    }
    print("{d}", .{safeCount});
}
