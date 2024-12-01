const std = @import("std");
const print = std.debug.print;

pub fn main() anyerror!void {
    var str: [5]u8 = "hello".*;
    str[0] = 'm';
    print_mem(&str);

    const arr = [_]u8 {65, 66, 67};
    var arr2 = arr;
    arr2[0] = 68;
    print("{s}\n", .{arr});
    print("{s}\n", .{arr2});
    const arr3 = returnStack();
    print("{d}\n", .{foo(arr[1..])});
    print("{any}\n", .{arr3});
}

fn returnStack() []const u8 {
    const res = [5]u8 { 1, 2, 3, 4, 5 };
    return res[0..];
}

fn foo(in: []const u8) u32 {
    var res: u32 = 0;
    for (in) |i| {
        res += i;
    }
    return res;
}

fn print_mem(in: []u8) void {
    const base = @intFromPtr(&in);
    const int_size = @sizeOf(u32);
    const pointer_size = @sizeOf(*u8);

    var i: usize = 0;
    while (i < pointer_size + int_size) : (i += 1) {
        const ptr: *u8 = @ptrFromInt(base + i);
        print("{d} ", .{ptr.*});
    }
    print("\n", .{});

    const in_ptr_as_int = @intFromPtr(in.ptr);
    print("in.ptr value: {d}\n", .{in_ptr_as_int});

    const in_ptr_ptr: *usize = @ptrFromInt(base);
    const in_ptr_as_int_2 = in_ptr_ptr.*;
    print("in.ptr value 2: {d}\n", .{in_ptr_as_int_2});

    const len_ptr: *u32 = @ptrFromInt(base + pointer_size);
    const len_2 = len_ptr.*;
    print("in.len: {d}\n", .{in.len});
    print("in.len 2: {d}\n", .{len_2});

    const str_ptr: [*:0]u8 = @ptrFromInt(in_ptr_as_int_2);
    print("string: {s}\n", .{in});
    print("string 2: {s}\n", .{str_ptr});
}

// output:
// 160 165 249 180 247 127 0 0 5 0 0 0 0
// in.ptr value: 140701869909408
// in.ptr value 2: 140701869909408
// in.len: 5
// in.len 2: 5
// string: mello
// string 2: mello
