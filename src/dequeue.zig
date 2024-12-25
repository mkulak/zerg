const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub fn ArrayDequeue(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: mem.Allocator,
        data: []T,
        start: usize,
        end: usize,
        // start inclusive, end exclusive
        // start == end means dequeue is empty
        // end == ((start - 1) mod data.len) means dequeue is full

        pub fn init(allocator: mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .data = &[_]T{},
                .start = 0,
                .end = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.data.len > 0) {
                self.allocator.free(self.data);
            }
        }

        pub fn addFirst(self: *Self, value: T) std.mem.Allocator.Error!void {
            try self.growIfNeeded();
            self.start = if (self.start == 0) self.data.len - 1 else self.start - 1;
            self.data[self.start] = value;
        }

        pub fn addLast(self: *Self, value: T) std.mem.Allocator.Error!void {
            try self.growIfNeeded();
            self.data[self.end] = value;
            self.end = if (self.end < self.data.len - 1) self.end + 1 else 0;
        }

        pub fn popLast(self: *Self) ?T {
            if (self.count() == 0) {
                return null;
            } else {
                self.end = if (self.end > 0) self.end - 1 else self.data.len - 1;
                return self.data[self.end];
            }
        }

        pub fn popFirst(self: *Self) ?T {
            if (self.getFirst()) |res| {
                self.start = if (self.start < self.data.len - 1) self.start + 1 else 0;
                return res;
            }
            return null;
        }

        pub fn getFirst(self: *Self) ?T {
            if (self.count() == 0) {
                return null;
            }
            return self.data[self.start];
        }

        pub fn getLast(self: *Self) ?T {
            if (self.count() == 0) {
                return null;
            } else {
                const lastIndex = if (self.end > 0) self.end - 1 else self.data.len - 1;
                return self.data[lastIndex];
            }
        }

        pub fn count(self: *Self) usize {
            if (self.start <= self.end) {
                return self.end - self.start;
            }
            return self.data.len - self.start + self.end;
        }

        pub fn iterator(self: *Self) QueueIterator(T) {
            return QueueIterator(T).init(self);
        }

        pub fn clear(self: *Self) void {
            self.end = self.start;
        }

        fn growIfNeeded(self: *Self) std.mem.Allocator.Error!void {
            if (self.data.len == 0) {
                self.data = try self.allocator.alloc(T, 10);
                return;
            }
            if (self.count() < self.data.len - 1) {
                return;
            }
            try self.ensureCapacity(self.data.len * 2);
        }

        pub fn ensureCapacity(self: *Self, newCapacity: usize) std.mem.Allocator.Error!void {
            const oldCapacity = self.data.len;
            if (oldCapacity >= newCapacity + 1) {
                return;
            }
            const newData = try self.allocator.alloc(T, newCapacity + 1);
            std.debug.print("Growing array from {d} to {d}", .{ self.data.len, newData.len });
            if (self.data.len > 0) {
                self.copyContentInOrder(newData);
                self.allocator.free(self.data);
                self.start = 0;
                self.end = oldCapacity - 1;
            }
            self.data = newData;
        }

        fn copyContentInOrder(self: *Self, dst: []T) void {
            if (self.start < self.end) {
                @memcpy(dst[0..self.count()], self.data[self.start..self.end]);
            } else {
                const prefix = self.data.len - self.start;
                @memcpy(dst[0..prefix], self.data[self.start..self.data.len]);
                @memcpy(dst[prefix .. prefix + self.end], self.data[0..self.end]);
            }
        }

        pub fn toOwnedSlice(self: *Self) std.mem.Allocator.Error![]T {
            const res = try self.allocator.alloc(T, self.count());
            self.copyContentInOrder(res);
            self.allocator.free(self.data);
            self.data.len = 0;
            self.start = 0;
            self.end = 0;
            return res;
        }
    };
}

fn QueueIterator(comptime T: type) type {
    return struct {
        dequeue: *ArrayDequeue(T),
        current: usize,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            // todo: handle concurrent modification
            if (self.current == self.dequeue.end) {
                return null;
            }
            const res = self.dequeue.data[self.current];
            self.current = if (self.current < self.dequeue.data.len - 1) self.current + 1 else 0;
            return res;
        }

        fn init(dequeue: *ArrayDequeue(T)) Self {
            return Self{ .dequeue = dequeue, .current = dequeue.start };
        }
    };
}

test "empty dequeue" {
    var unit = ArrayDequeue(u32).init(testing.allocator);
    try testing.expect(unit.count() == 0);
    try testing.expect(unit.popFirst() == null);
    try testing.expect(unit.popLast() == null);
    try testing.expect(unit.count() == 0);
}

test "basic dequeue operations" {
    var unit = ArrayDequeue(u32).init(testing.allocator);
    defer unit.deinit();

    try unit.addLast(1);
    try testing.expectEqual(1, unit.count());
    try unit.addLast(2);
    try unit.addLast(3);
    try testing.expectEqual(3, unit.count());
    var iter = unit.iterator();
    var expected: u32 = 1;
    while (iter.next()) |elem| {
        try testing.expectEqual(expected, elem);
        expected += 1;
    }
    try testing.expectEqual(4, expected);
    try testing.expectEqual(3, unit.count());

    try testing.expectEqual(1, unit.getFirst());
    try testing.expectEqual(1, unit.getFirst());
    try testing.expectEqual(1, unit.popFirst());
    try testing.expectEqual(2, unit.count());
    try testing.expectEqual(3, unit.getLast());
    try testing.expectEqual(3, unit.getLast());
    try testing.expectEqual(3, unit.popLast());
    try testing.expectEqual(1, unit.count());

    try unit.addLast(2);
    unit.clear();
    try testing.expectEqual(0, unit.count());
    try unit.addLast(11);
    try unit.addFirst(10);
    try testing.expectEqual(10, unit.getFirst());
    try testing.expectEqual(11, unit.getLast());
}

test "wrap around from the left" {
    var unit = ArrayDequeue(u8).init(testing.allocator);
    defer unit.deinit();

    try unit.addFirst('C');
    try testing.expectEqual(1, unit.count());
    try unit.addFirst('B');
    try unit.addFirst('A');
    try testing.expectEqual(3, unit.count());
    var iter = unit.iterator();
    var expected: u8 = 'A';
    while (iter.next()) |elem| {
        try testing.expectEqual(expected, elem);
        expected += 1;
    }
    try testing.expectEqual('D', expected);
    try testing.expectEqual(3, unit.count());

    try unit.addLast('D');
    try testing.expectEqual('D', unit.getLast());
    try testing.expectEqual('A', unit.getFirst());

    expected = 'A';
    iter = unit.iterator();
    while (iter.next()) |elem| {
        try testing.expectEqual(expected, elem);
        expected += 1;
    }
    try testing.expectEqual('E', expected);

    _ = unit.popLast();
    _ = unit.popFirst();
    _ = unit.popFirst();
    _ = unit.popFirst();
    try testing.expectEqual(0, unit.count());

    try unit.addLast('B');
    try unit.addFirst('A');
    try testing.expectEqual(2, unit.count());


    const content = try contentToString(&unit);
    defer testing.allocator.free(content);

    try testing.expectEqualStrings("AB", content);
 }

test "wrap around from the right" {
    var unit = ArrayDequeue(u8).init(testing.allocator);
    defer unit.deinit();

    try unit.ensureCapacity(5);

    for ("ABCDE") |ch| {
        try unit.addLast(ch);
    }
    try testing.expectEqual(5, unit.count());

    _ = unit.popFirst();
    try unit.addLast('X');
    try testing.expectEqual(5, unit.count());

    const content = try contentToString(&unit);
    defer testing.allocator.free(content);
    try testing.expectEqualStrings("BCDEX", content);

    _ = unit.popFirst();
    try unit.addLast('Y');
    try testing.expectEqual(5, unit.count());

    const content2 = try contentToString(&unit);
    defer testing.allocator.free(content2);
    try testing.expectEqualStrings("CDEXY", content2);
 }

test "storage growth via addLast when start < end" {
    var unit = ArrayDequeue(u8).init(testing.allocator);
    defer unit.deinit();
    for ("ABCDEFGHI") |ch| {
        try unit.addLast(ch);
    }
    try testing.expectEqual(9, unit.count());
    _ = unit.popFirst();
    try unit.addLast('X');
    try testing.expectEqual(9, unit.count());
    try unit.addLast('Y');
    try testing.expectEqual(10, unit.count());
    try unit.addLast('Z');
    try testing.expectEqual(11, unit.count());

    const content = try contentToString(&unit);
    defer testing.allocator.free(content);

    try testing.expectEqualStrings("BCDEFGHIXYZ", content);
}

test "storage growth via addFirst when start < end" {
    var unit = ArrayDequeue(u8).init(testing.allocator);
    defer unit.deinit();

    for ("ABCDEFGHI") |ch| {
        try unit.addLast(ch);
    }
    try testing.expectEqual(9, unit.count());
    try unit.addFirst('2');
    try testing.expectEqual(10, unit.count());
    try unit.addFirst('1');
    try testing.expectEqual(11, unit.count());
    try unit.addLast('Z');
    try testing.expectEqual(12, unit.count());

    const content = try contentToString(&unit);
    defer testing.allocator.free(content);

    try testing.expectEqualStrings("12ABCDEFGHIZ", content);
}

test "storage growth via addLast when start > end" {
    var unit = ArrayDequeue(u8).init(testing.allocator);
    defer unit.deinit();

    for ("ABCDEFG") |ch| {
        try unit.addLast(ch);
    }
    try testing.expectEqual(7, unit.count());
    try unit.addFirst('2');
    try testing.expectEqual(8, unit.count());
    try unit.addFirst('1');
    try testing.expectEqual(9, unit.count());
    try unit.addLast('Y');
    try unit.addLast('Z');
    try testing.expectEqual(11, unit.count());

    const content = try contentToString(&unit);
    defer testing.allocator.free(content);

    try testing.expectEqualStrings("12ABCDEFGYZ", content);
}

test "storage growth via addFirst when start > end" {
    var unit = ArrayDequeue(u8).init(testing.allocator);
    defer unit.deinit();

    for ("ABCDEFG") |ch| {
        try unit.addLast(ch);
    }
    try testing.expectEqual(7, unit.count());
    try unit.addFirst('3');
    try testing.expectEqual(8, unit.count());
    try unit.addFirst('2');
    try testing.expectEqual(9, unit.count());
    try unit.addFirst('1');
    try unit.addFirst('0');
    try testing.expectEqual(11, unit.count());

    const content = try contentToString(&unit);
    defer testing.allocator.free(content);

    try testing.expectEqualStrings("0123ABCDEFG", content);
}

test "toOwnedSlice" {
    var unit = ArrayDequeue(u8).init(testing.allocator);
    defer unit.deinit();

    for ("ABCDEF") |ch| {
        try unit.addLast(ch);
    }
    for ("210") |ch| {
        try unit.addFirst(ch);
    }

    try testing.expectEqual(9, unit.count());

    const actual = try unit.toOwnedSlice();
    defer testing.allocator.free(actual);
    try testing.expectEqualStrings("012ABCDEF", actual);
}

fn print(dequeue: *ArrayDequeue(u8)) void {
    std.debug.print("[start: {d}, end: {d}, data: {s}]\n", .{ dequeue.start, dequeue.end, dequeue.data });
}

fn contentToString(dequeue: *ArrayDequeue(u8)) ![]u8 {
    var iter = dequeue.iterator();
    var elems = std.ArrayList(u8).init(testing.allocator);
    defer elems.deinit();

    while (iter.next()) |elem| {
        try elems.append(elem);
    }
    return elems.toOwnedSlice();
}
