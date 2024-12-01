const std = @import("std");
const posix = std.posix;
const print = std.debug.print;

pub fn main() anyerror!void {
    const pid = try posix.fork();
    print("fork result: {any}\n", .{pid});
    posix.nanosleep(0, 10);
    var tp: posix.timespec = undefined;
    try posix.clock_gettime(std.posix.CLOCK.REALTIME, &tp);
    print("current time: {any} {any}\n", .{tp.tv_sec, tp.tv_nsec});
    if (pid != 0) {
        _ = posix.waitpid(pid, 0);
    }
}

