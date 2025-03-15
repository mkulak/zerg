const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const Backend = dvui.backend;

const window_icon_png = @embedFile("zig-favicon.png");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

const vsync = false;

var g_backend: ?Backend = null;
var g_win: ?*dvui.Window = null;

pub fn main() !void {
    defer if (gpa_instance.deinit() != .ok) @panic("Memory leak on exit!");
    var backend = try Backend.initWindow(.{
        .allocator = gpa,
        .size = .{ .w = 1000.0, .h = 800.0 },
        .min_size = .{ .w = 250.0, .h = 350.0 },
        .vsync = vsync,
        .title = "Points",
        .icon = window_icon_png, // can also call setIconFromFileContent()
    });
    defer backend.deinit();
    g_backend = backend;

    var win = try dvui.Window.init(@src(), gpa, backend.backend(), .{});
    defer win.deinit();

    main_loop: while (true) {
        const nstime = win.beginWait(backend.hasEvent());
        try win.begin(nstime);
        const quit = try backend.addAllEvents(&win);
        if (quit) break :main_loop;

        _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 0, 0, 255);
        _ = Backend.c.SDL_RenderClear(backend.renderer);

        check_input();
        try gui_frame();

        const end_micros = try win.end(.{});

        backend.setCursor(win.cursorRequested());
        backend.textInputRect(win.textInputRequested());
        backend.renderPresent();
        const wait_event_micros = win.waitTime(end_micros, null);
        backend.waitEventTimeout(wait_event_micros);
    }
}

fn check_input() void {
    const evts = dvui.events();

    for (evts) |e| {
        switch (e.evt) {
            .mouse => |me| {
                mouseCur = me.p;
                if (me.action == .press) {
                    std.debug.print("Mouse down at ({d:.2}, {d:.2})\n", .{ me.p.x, me.p.y });
                    mouseDown = me.p;
                }
                if (me.action == .release) {
                    std.debug.print("Mouse up at ({d:.2}, {d:.2})\n", .{ me.p.x, me.p.y });
                    mouseDown = null;
                    mouseUp = me.p;
                }
                if (me.action == .motion) {
                    // std.debug.print("Mouse moved to ({d:.2}, {d:.2})\n", .{ me.p.x, me.p.y });
                }
            },
            else => {},
        }
    }
}

// both dvui and SDL drawing
fn gui_frame() !void {
    const backend = g_backend orelse return;

    var scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both, .color_fill = .{ .name = .fill_window } });
    defer scroll.deinit();

    var tl = try dvui.textLayout(@src(), .{}, .{ .expand = .horizontal, .font_style = .title_4 });
    const lorem = "Quad tree demo";
    try tl.addText(lorem, .{});
    tl.deinit();


    {
        var box = try dvui.box(@src(), .horizontal, .{ .expand = .both, .background = false, .margin = .{ .x = 8, .w = 8 } });
        defer box.deinit();

        // Here is some arbitrary drawing that doesn't have to go through DVUI.
        // It can be interleaved with DVUI drawing.
        // NOTE: This only works in the main window (not floating subwindows
        // like dialogs).

        // get the screen rectangle for the box
        const rs = box.data().contentRectScale();
        if (!initialized) {
            const mr = dvui.RectScale{ .r = .{ .x = 0, .y = 0, .w = 1000, .h = 800 }, .s = rs.s };
            init(mr);
            initialized = true;
        }
        // rs.r is the pixel rectangle, rs.s is the scale factor (like for
        // hidpi screens or display scaling)
        var rect: Backend.c.SDL_FRect = .{
            .x = (rs.r.x + 4 * rs.s),
            .y = (rs.r.y + 4 * rs.s),
            .w = (20 * rs.s),
            .h = (20 * rs.s),
        };
        _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 255, 0, 0, 255);
        _ = Backend.c.SDL_RenderFillRect(backend.renderer, &rect);

        rect.x += 24 * rs.s;
        _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 255, 0, 255);
        _ = Backend.c.SDL_RenderFillRect(backend.renderer, &rect);

        rect.x += 24 * rs.s;
        _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 0, 255, 255);
        _ = Backend.c.SDL_RenderFillRect(backend.renderer, &rect);
        _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 255, 0, 255, 255);
        _ = Backend.c.SDL_RenderLine(backend.renderer, (rs.r.x + 4 * rs.s), (rs.r.y + 30 * rs.s), (rs.r.x + rs.r.w - 8 * rs.s), (rs.r.y + 30 * rs.s));

        if (mouseDown) |md| {
            _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 255, 255, 0);
            const mc = mouseCur orelse unreachable;
            rect.x = md.x;
            rect.y = md.y;
            rect.w = mc.x - md.x;
            rect.h = mc.y - md.y;
            _ = Backend.c.SDL_RenderFillRect(backend.renderer, &rect);
        }

        for (points) |p| {
            _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 255, 0, 255);
            rect.x = p.x;
            rect.y = p.y;
            rect.w = 10;
            rect.h = 10;
            _ = Backend.c.SDL_RenderFillRect(backend.renderer, &rect);
        }
    }
}

fn init(rs: dvui.RectScale) void {
    var gen = std.Random.DefaultPrng.init(43439533);
    var random = gen.random();
    for (0..points.len) |i| {
        const x: f32 = random.float(f32) * rs.r.w * rs.s;
        const y: f32 = random.float(f32) * rs.r.h * rs.s;
        points[i] = XY{ .x = x, .y = y };
    }
}

var points: [100]XY = undefined;
var initialized: bool = false;

var mouseDown: ?dvui.Point = null;
var mouseUp: ?dvui.Point = null;
var mouseCur: ?dvui.Point = null;

const XY = struct { x: f32, y: f32 };
