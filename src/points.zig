const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const Backend = dvui.backend;

const window_icon_png = @embedFile("zig-favicon.png");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

const vsync = false;
var scale_val: f32 = 1.0;

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

        try gui_frame();

        const end_micros = try win.end(.{});

        backend.setCursor(win.cursorRequested());
        backend.textInputRect(win.textInputRequested());
        backend.renderPresent();
        const wait_event_micros = win.waitTime(end_micros, null);
        backend.waitEventTimeout(wait_event_micros);
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

    var tl2 = try dvui.textLayout(@src(), .{}, .{ .expand = .horizontal });
    try tl2.addText("DVUI", .{});
    tl2.deinit();

    const label = if (dvui.Examples.show_demo_window) "Hide Demo Window" else "Show Demo Window";
    if (try dvui.button(@src(), label, .{}, .{})) {
        dvui.Examples.show_demo_window = !dvui.Examples.show_demo_window;
    }

    {
        var scaler = try dvui.scale(@src(), scale_val, .{ .expand = .horizontal });
        defer scaler.deinit();

        {
            var hbox = try dvui.box(@src(), .horizontal, .{});
            defer hbox.deinit();

            if (try dvui.button(@src(), "Zoom In", .{}, .{})) {
                scale_val = @round(dvui.themeGet().font_body.size * scale_val + 1.0) / dvui.themeGet().font_body.size;
            }

            if (try dvui.button(@src(), "Zoom Out", .{}, .{})) {
                scale_val = @round(dvui.themeGet().font_body.size * scale_val - 1.0) / dvui.themeGet().font_body.size;
            }
        }

        try dvui.labelNoFmt(@src(), "Below is drawn directly by the backend, not going through DVUI.", .{ .margin = .{ .x = 4 } });

        var box = try dvui.box(@src(), .horizontal, .{ .expand = .horizontal, .min_size_content = .{ .h = 40 }, .background = true, .margin = .{ .x = 8, .w = 8 } });
        defer box.deinit();

        // Here is some arbitrary drawing that doesn't have to go through DVUI.
        // It can be interleaved with DVUI drawing.
        // NOTE: This only works in the main window (not floating subwindows
        // like dialogs).

        // get the screen rectangle for the box
        const rs = box.data().contentRectScale();

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

        for (points) |p| {
            _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 0, 255, 0, 255);
            rect.x = p.x;
            rect.y = p.y;
            rect.w = 10;
            rect.h = 10;
            _ = Backend.c.SDL_RenderFillRect(backend.renderer, &rect);
        }
    }
    const evts = dvui.events();
    for (evts) |e| {
        switch (e.evt) {
            .mouse => |me| {
                if (me.action == .press) {
                    std.debug.print("Mouse down at ({d:.2}, {d:.2})\n", .{ me.p.x, me.p.y });
                }
                if (me.action == .release) {
                    std.debug.print("Mouse up at ({d:.2}, {d:.2})\n", .{ me.p.x, me.p.y });
                }
                if (me.action == .motion) {
                    // std.debug.print("Mouse moved to ({d:.2}, {d:.2})\n", .{ me.p.x, me.p.y });
                }
            },
            else => {},
        }
    }
}

const points = blk: {
    @setEvalBranchQuota(10000);
    var gen = std.Random.DefaultPrng.init(43439533);
    var random = gen.random();
    var data: [100]XY = undefined;
    for(0..data.len) |i| {
        const x: f32 = @floatFromInt(random.intRangeAtMost(u32, 0, 2000));
        const y: f32 = @floatFromInt(random.intRangeAtMost(u32, 0, 1600));
        data[i] = XY { .x = x, .y = y};
    }
    break :blk data;
};

const XY = struct { x: f32, y: f32 };
