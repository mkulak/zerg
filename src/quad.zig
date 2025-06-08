const std = @import("std");
const Quad = @This();

const inf = std.math.inf(f32);

pub const Point = struct {
    x: f32,
    y: f32,
};

pub const Box = struct {
    min: Point = .{ .x = inf, .y = inf },
    max: Point = .{ .x = -inf, .y = -inf },

    const Self = @This();

    pub fn extend(self: *Self, p: Point) void {
        self.min.x = @min(self.min.x, p.x);
        self.min.y = @min(self.min.y, p.y);
        self.max.x = @max(self.max.x, p.x);
        self.max.y = @max(self.max.y, p.y);
    }
};

pub const box = Box{};

pub fn middle(p1: Point, p2: Point) Point {
    return .{ .x = (p1.x + p2.x) / 2, .y = (p1.y + p2.y) / 2 };
}

pub fn bbox(points: []Point) Box {
    var res = Box {};
    for (points) |p| {
        res.extend(p);
    }
    return res;
}

const NodeId = usize;
const nullId: NodeId = std.math.maxInt(NodeId);

const Node = struct {
    children: [2][2]NodeId
};

const QuadTree = struct {
    bbox: Box,
    root: NodeId,
    nodes: std.ArrayList(Node),

    const Self = @This();

    fn build(points: []Point, alloc: std.mem.Allocator) Self {
        var res: Self = undefined;
        res.nodes = std.ArrayList(Node).init(alloc);
        res.bbox = bbox(points);
        res.root = res.build_impl(points);
        return res;
    }

    fn buildImpl(self: *Self, points: []Point) ?NodeId {
        if (points.len == 0) return null;
        const result = self.nodes.items.len;
        self.nodes.append(.{});
        if (points.len == 1) return result;
        const center = middle(self.bbox.min, self.bbox.max);
        const splitY = partition(points, center, true);
        const splitXLower = partition(points[0..splitY], center, false);
        const splitXUpper = partition(points[splitY..points.len], center, false);
        self.nodes.items[result].children[0][0] = self.buildImpl(points[0..splitXLower]);
        self.nodes.items[result].children[0][1] = self.buildImpl(points[splitXLower..splitY]);
        self.nodes.items[result].children[1][0] = self.buildImpl(points[splitY..splitXUpper]);
        self.nodes.items[result].children[1][1] = self.buildImpl(points[splitXUpper..]);
        return result;
    }
};

fn partition(points: []Point, center: Point, useY: bool) usize {
    var start: usize = 0;
    var end: usize = points.len;
    while (start < end) {
        const shouldStay = if (useY) points[start].y < center.y else points[start].x < center.x;
        if (shouldStay) {
            start +=1;
        } else {
            const endPoint = points[end];
            points[end] = points[start];
            points[start] = endPoint;
            end -= 1;
        }
    }
    return start - 1;
}

pub fn main() void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    var points = [_]Point { .{.x = 1, .y = 2}};
    const q = QuadTree.build(&points, allocator);
    std.debug.print("{any}\n", .{q});
}




