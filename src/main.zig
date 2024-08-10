const std = @import("std");
const r = @import("root.zig");
const expect = std.testing.expect;
const print = std.debug.print;
pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    print("All your {s} are belong to us.\n", .{"codebase"});
    try printMsg();
    const res = r.add(1, 2);
    std.debug.print("blah {}\n", .{res});
    const file = try std.fs.cwd().createFile("1.txt", .{});
    defer file.close();
    try file.writeAll("hello zig");

    const str = "Misha Tra Ta ta";
    const sub = str[3..str.len - 3];
    print(sub, .{});
}

fn printMsg() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Run `zig build test` to run the tests.\n", .{});
    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
    try expect(false);
}
