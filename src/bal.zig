const std = @import("std");
const print = std.debug.print;

// always prints values that are divisible by 256
// i.e. 0x1087cdc00 or 0x1087c3a00

var foo: u8 align(256) = 92;

pub fn main() anyerror!void {
    const bar: u8 align(256) = 92;
    // const str: *const [5:0]u8 = "hello";
    // const str: []const u8 = "hello";
    var str: [5]u8 = "hello".*;
    // var str: [5]u8 = [_]u8{'h', 'e', 'l', 'l', 'o'};
    print("address of foo: 0x{x}\n", .{@intFromPtr(&foo)});
    print("address of bar: 0x{x}\n", .{@intFromPtr(&bar)});
    print("str={s}\n", .{str});
    str[0] = 'm';
    // const slice = str[0..];
    // const strPtr: *const u8 = &str[0];
    // const slice = strPtr[0..1];
    // const nextPtr: [*]const u8 = slice;
    // print("{d}\n", .{strPtr.*});
    // const int_ptr: usize = @intFromPtr(&str[0]);
    // var i: usize = 0;
    // while (i <= 4) : (i += 1) {
    //     print("{c} ", .{str[i]});
    // }
    // print("\n", .{});
    print_mem(&str);
}

fn print_mem(in: []u8) void {
    const int_size = @sizeOf(u32);
    const pointer_size = @sizeOf(*u8);
    print("sizeOf u32: {d}\n", .{int_size});
    print("sizeOf *u8: {d}\n", .{pointer_size});


    const in_ptr_as_int = @intFromPtr(in.ptr);
    print("in.ptr value: {d}\n", .{in_ptr_as_int});

    const base = @intFromPtr(&in);

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

    // var i: usize = 0;
    // while (i <= 20) : (i += 1) {
    //     const ptr: *u8 = @ptrFromInt(base + i);
    //     print("{d} ", .{ptr.*});
    // }
    print("\n", .{});

    // i = 0;
    // while (i <= 20) : (i += 1) {
    //     const ptr: *u8 = @ptrFromInt(base + i);
    //     print("{c} ", .{ptr.*});
    // }
    // print("\n", .{});
}
// 1000_0000 1010_0100