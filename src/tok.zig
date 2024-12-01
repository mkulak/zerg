const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const input = "ololo blah, ,   go";
    var tokenizer = std.mem.tokenize(u8, input, " ,");
    for (0..5) |i| {
        const word = tokenizer.next();
        print("word {d}: {s}\n", .{ i + 1, word orelse "<empty>" });
    }
}
