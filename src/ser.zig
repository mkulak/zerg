const std = @import("std");

const Foo = struct {
    bar: u8,
    foo: u32,
};

pub fn main() anyerror!void {
    const foo1 = Foo { .bar = 1, .foo = 11 };
    const foo2 = Foo { .bar = 2, .foo = 22 };
    const arr = [_] Foo {foo1, foo2};

    const arrSize = @sizeOf(@TypeOf(arr));
    std.debug.print("Foo: {any}\n", .{@sizeOf(Foo)});
    std.debug.print("arr: {any}\n", .{arrSize});

    const cwd: std.fs.Dir = std.fs.cwd();
    var output_dir: std.fs.Dir = try cwd.openDir(".", .{});
    defer output_dir.close();
    const file: std.fs.File = try output_dir.createFile("out.txt", .{});
    defer file.close();

    const u8ptr: [*]const u8 = @ptrCast(&arr);
    const byte_written = try file.write(u8ptr[0..arrSize]);
    std.debug.print("Successfully wrote {d} bytes.\n", .{byte_written});

    const file2 = try output_dir.openFile("out.txt", .{});
    defer file2.close();
    var input:[arrSize]u8 align(@alignOf(Foo)) = undefined;
    const readBytes = try file2.read(&input);
    std.debug.print("Successfully read {d} bytes.\n", .{readBytes});

    std.debug.print("arr: {any}\n", .{arr});
    std.debug.print("input: {any}\n", .{input});

    const deser: [*]Foo = @ptrCast(&input);
    std.debug.print("deser: {any}\n", .{deser[0..arr.len]});
}
