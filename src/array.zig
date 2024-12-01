const print = @import("std").debug.print;

pub fn main() void {
    // const a: [5]u8 = "array".*;
    // var arr = [_]u8 { 1, 2, 3};
    // const arr_ptr = &arr;
    // _ = a;
    // arr[0] = 11;
    // arr = [_]u8 { 4, 4, 4};
    // print("{any}\n", .{arr});
    // print("{any}\n", .{arr_ptr.*});
    var a: u32 = 2;
    var b: u32 = 3;
    print("a={any} b={any}\n", .{a, b});
    //a = a + b;
    //b = a - b;
    //a = a - b;
    
    // a = a ^ b;
    // b = a ^ b;
    // a = a ^ b;

    a ^= b;
    b ^= a;
    a ^= b;
    print("a={any} b={any}\n", .{a, b});

    const arr1 = [_]u8 { 2, 3, 4};
    const arr2 = [_]u8 { 6, 7, 9, 10};

    pri(&arr1, &arr2);
}

fn pri(a: []const u8, b: []const u8) void {
    // this works
    for (a, 0..) |ai, bi| {
        print("({d},{d}) ", .{ai, bi});
    }
    print("\n", .{});
    // this doesn't: thread 2804514 panic: for loop over objects with non-equal lengths
    for (a, b) |ai, bi| {
        print("({d},{d}) ", .{ai, bi});
    }
}