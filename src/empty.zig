const std = @import("std");
const print = std.debug.print;


pub fn main() !void {
    var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer general_purpose_allocator.deinit();
    const my: MyS =  .{ .size = 0 };
    // const my2: MyS =  .empty;
    print("{}", .{my});
    print("{}", .{MyS.empty});
    // print("{}", .{my2});
}

const MyS = struct {
    size: usize,

    pub const empty: MyS = .{ .size = 0 };
};