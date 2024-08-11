const std = @import("std");
const r = @import("root.zig");
const expect = std.testing.expect;
const print = std.debug.print;

const rl = @import("raylib");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const MAX_LIGHTS = 4;
var lightsCount: usize = 0;

pub fn main() anyerror!void {
    defer _ = gpa.deinit();
    const screenWidth = 800;
    const screenHeight = 450;
    rl.setConfigFlags(.{ .msaa_4x_hint = true }); // Enable Multi Sampling Anti Aliasing 4x (if available)

    rl.initWindow(screenWidth, screenHeight, "raylib-zig for the win");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var camera: rl.Camera = rl.Camera3D{
        .position = rl.Vector3.init(2.0, 4.0, 6.0),
        .target = rl.Vector3.init(0.0, 0.5, 0.0),
        .up = rl.Vector3.init(0.0, 1.0, 0.0),
        .fovy = 45.0,
        .projection = rl.CameraProjection.camera_perspective,
    };

    const shader: rl.Shader = rl.loadShader("lighting.vs", "lighting.fs");
    defer rl.unloadShader(shader);

    // Get some required shader locations
    const view: usize = @intCast(@intFromEnum(rl.ShaderLocationIndex.shader_loc_vector_view));
    shader.locs[view] = rl.getShaderLocation(shader, "viewPos");
    const ambientLoc = rl.getShaderLocation(shader, "ambient");
    rl.setShaderValue(shader, ambientLoc, &[_]f32{ 0.1, 0.1, 0.1, 1.0 }, rl.ShaderUniformDataType.shader_uniform_vec4);

    var lights = [MAX_LIGHTS]Light{
        try createLight(1, rl.Vector3.init(-2.0, 1.0, -2.0), rl.Vector3.zero(), rl.Color.yellow, shader),
        try createLight(1, rl.Vector3.init(2.0, 1.0, 2.0), rl.Vector3.zero(), rl.Color.red, shader),
        try createLight(1, rl.Vector3.init(-2.0, 1.0, 2.0), rl.Vector3.zero(), rl.Color.green, shader),
        try createLight(1, rl.Vector3.init(2.0, 1.0, -2.0), rl.Vector3.zero(), rl.Color.blue, shader),
    };

    while (!rl.windowShouldClose()) {
        rl.updateCamera(&camera, rl.CameraMode.camera_orbital);
        const cameraPos = [3]f32{ camera.position.x, camera.position.y, camera.position.z };
        rl.setShaderValue(shader, shader.locs[view], &cameraPos, rl.ShaderUniformDataType.shader_uniform_vec3);

        if (rl.isKeyPressed(rl.KeyboardKey.key_y)) {
            lights[0].enabled = !lights[0].enabled;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
            lights[1].enabled = !lights[1].enabled;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_g)) {
            lights[2].enabled = !lights[2].enabled;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_b)) {
            lights[3].enabled = !lights[3].enabled;
        }

        for (0..MAX_LIGHTS) |i| {
            updateLightValues(shader, lights[i]);
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.white);

        rl.beginMode3D(camera);
        rl.beginShaderMode(shader);

        rl.drawPlane(rl.Vector3.zero(), rl.Vector2.init(10.0, 10.0), rl.Color.white);
        rl.drawCube(rl.Vector3.zero(), 2.0, 4.0, 2.0, rl.Color.white);

        rl.endShaderMode();

        for (0..MAX_LIGHTS) |i| {
            if (lights[i].enabled) {
                rl.drawSphereEx(lights[i].position, 0.2, 8, 8, lights[i].color);
            } else {
                rl.drawSphereWires(lights[i].position, 0.2, 8, 8, rl.colorAlpha(lights[i].color, 0.3));
            }
        }

        rl.drawGrid(10, 1.0);
        rl.endMode3D();
        rl.drawFPS(10, 10);

        rl.drawText("Use keys [Y][R][G][B] to toggle lights", 10, 40, 20, rl.Color.dark_gray);
    }
}

fn createLight(lightType: i32, position: rl.Vector3, target: rl.Vector3, color: rl.Color, shader: rl.Shader) !Light {
    if (lightsCount >= MAX_LIGHTS) {
        return LightError.TooManyLights;
    }
    const light = Light{
        .enabled = true,
        .type = lightType,
        .position = position,
        .target = target,
        .color = color,
        .enabledLoc = try getLightValue(shader, "enabled", lightsCount),
        .typeLoc = try getLightValue(shader, "type", lightsCount),
        .positionLoc = try getLightValue(shader, "position", lightsCount),
        .targetLoc = try getLightValue(shader, "target", lightsCount),
        .colorLoc = try getLightValue(shader, "color", lightsCount),
    };
    updateLightValues(shader, light);
    lightsCount += 1;
    return light;
}

fn getLightValue(shader: rl.Shader, param: []const u8, light: usize) !i32 {
    const name: []u8 = try std.fmt.allocPrint(allocator, "lights[{d}].{s}a", .{ light, param });
    defer allocator.free(name);
    name[name.len - 1] = 0;
    return rl.getShaderLocation(shader, name[0..name.len-1:0]);
}

fn updateLightValues(shader: rl.Shader, light: Light) void {
    // Send to shader light enabled state and type
    rl.setShaderValue(shader, light.enabledLoc, &light.enabled, rl.ShaderUniformDataType.shader_uniform_int);
    rl.setShaderValue(shader, light.typeLoc, &light.type, rl.ShaderUniformDataType.shader_uniform_int);

    // Send to shader light position values
    const position = [_]f32{ light.position.x, light.position.y, light.position.z };
    rl.setShaderValue(shader, light.positionLoc, &position, rl.ShaderUniformDataType.shader_uniform_vec3);

    // Send to shader light target position values
    const target = [_]f32{ light.target.x, light.target.y, light.target.z };
    rl.setShaderValue(shader, light.targetLoc, &target, rl.ShaderUniformDataType.shader_uniform_vec3);

    // Send to shader light color values
    const color = [_]f32{ @as(f32, @floatFromInt(light.color.r)) / 255.0, @as(f32, @floatFromInt(light.color.g)) / 255.0, @as(f32, @floatFromInt(light.color.b)) / 255.0, @as(f32, @floatFromInt(light.color.a)) / 255.0 };
    rl.setShaderValue(shader, light.colorLoc, &color, rl.ShaderUniformDataType.shader_uniform_vec4);
}

pub const Light = struct {
    type: i32,
    enabled: bool,
    position: rl.Vector3,
    target: rl.Vector3,
    color: rl.Color,
    // attenuation: f32,

    // Shader locations
    enabledLoc: i32,
    typeLoc: i32,
    positionLoc: i32,
    targetLoc: i32,
    colorLoc: i32,
    // attenuationLoc: i32,
};

const LightError = error{
    TooManyLights,
};
