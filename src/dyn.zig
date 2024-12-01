const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const Foo32 = create(u32);
    const foo = Foo32 { .foo = 11};
    print("{any}", .{foo});
}

fn create(comptime T: type) type {
    return struct {
        foo: T
    };
}