const print = @import("std").debug.print;

pub fn main() anyerror!void {
    const arr1 = returnStack();
    const arr2 = returnStack2();

    print("{any}\n", .{arr1});
    print("{any}\n", .{arr2});
}

fn returnStack() []u8 {
    var res = [5]u8 { 1, 2, 3, 4, 5 };
    return res[0..];
}

fn returnStack2() []u8 {
    var res2 = [_]u8 { 1 } ** 10;
    return res2[0..];
}