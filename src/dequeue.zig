const std = @import("std");
const mem = std.mem;
const testing = std.testing;

fn ArrayDequeue(comptime T: type) type {
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
            self.end = (self.end + 1) % self.data.len;
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

        fn growIfNeeded(self: *Self) std.mem.Allocator.Error!void {
            if (self.data.len == 0) {
                self.data = try self.allocator.alloc(T, 10);
                return;
            }
            if (self.count() < self.data.len - 1) {
                return;
            }
            const oldLen = self.data.len;
            const newData = try self.allocator.alloc(T, oldLen * 2);
            if (self.start < self.end) {
                @memcpy(newData, self.data[self.start..self.end]);
            } else {
                @memcpy(newData, self.data[self.start..oldLen]);
                @memcpy(newData[oldLen - self.start ..], self.data[0..self.end]);
            }
            self.allocator.free(self.data);
            self.data = newData;
            self.start = 0;
            self.end = oldLen;
        }
    };
}

pub fn QueueIterator(comptime T: type) type {
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
}

test "wrap around" {
    var unit = ArrayDequeue(u32).init(testing.allocator);
    defer unit.deinit();

    try unit.addFirst(3);
    try testing.expectEqual(1, unit.count());
    try unit.addFirst(2);
    try unit.addFirst(1);
    try testing.expectEqual(3, unit.count());
    var iter = unit.iterator();
    var expected: u32 = 1;
    while (iter.next()) |elem| {
        try testing.expectEqual(expected, elem);
        expected += 1;
    }
    try testing.expectEqual(4, expected);
    try testing.expectEqual(3, unit.count());

    try unit.addLast(4);
    try testing.expectEqual(4, unit.getLast());
    try testing.expectEqual(1, unit.getFirst());

    expected = 1;
    iter = unit.iterator();
    while (iter.next()) |elem| {
        try testing.expectEqual(expected, elem);
        expected += 1;
    }
    try testing.expectEqual(5, expected);
}

