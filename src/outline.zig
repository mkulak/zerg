const rl = @import("raylib");
const std = @import("std");

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib [shaders] example - Apply an outline to a texture");
    defer rl.closeWindow(); // Close window and OpenGL context

    const texture: rl.Texture = rl.Texture.init("fudesumi.png");
    defer rl.unloadTexture(texture);

    const shdrOutline: rl.Shader = rl.loadShader(null, "outline.fs");
    defer rl.unloadShader(shdrOutline);

    var outlineSize: f32 = 2.0;
    const outlineColor = [4]f32{ 1.0, 0.0, 0.0, 1.0 }; // Normalized RED color
    const textureSize = rl.Vector2.init(
        @as(f32, @floatFromInt(texture.width)),
        @as(f32, @floatFromInt(texture.height)),
    );

    // Get shader locations
    const outlineSizeLoc = rl.getShaderLocation(shdrOutline, "outlineSize");
    const outlineColorLoc = rl.getShaderLocation(shdrOutline, "outlineColor");
    const textureSizeLoc = rl.getShaderLocation(shdrOutline, "textureSize");

    // Set shader values (they can be changed later)
    rl.setShaderValue(
        shdrOutline,
        outlineSizeLoc,
        &outlineSize,
        rl.ShaderUniformDataType.shader_uniform_float,
    );
    rl.setShaderValue(
        shdrOutline,
        outlineColorLoc,
        &outlineColor,
        rl.ShaderUniformDataType.shader_uniform_vec4,
    );
    rl.setShaderValue(
        shdrOutline,
        textureSizeLoc,
        &textureSize,
        rl.ShaderUniformDataType.shader_uniform_vec2,
    );

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        outlineSize += rl.getMouseWheelMove();
        if (outlineSize < 1.0) outlineSize = 1.0;

        rl.setShaderValue(
            shdrOutline,
            outlineSizeLoc,
            &outlineSize,
            rl.ShaderUniformDataType.shader_uniform_float,
        );
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        {
            rl.beginShaderMode(shdrOutline);
            defer rl.endShaderMode();

            texture.draw(
                @divFloor(rl.getScreenWidth(), 2) - @divFloor(texture.width, 2),
                -30,
                rl.Color.white,
            );
        }

        rl.drawText("Shader-based\ntexture\noutline", 10, 10, 20, rl.Color.gray);

        rl.drawText(
            rl.textFormat("Outline size: %i px", .{@as(i32, @intFromFloat(outlineSize))}),
            10,
            120,
            20,
            rl.Color.maroon,
        );

        rl.drawFPS(710, 10);
        //----------------------------------------------------------------------------------
    }
}