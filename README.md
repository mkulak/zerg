Zig + Raylib sample project
==
Port of [raylib shader example](https://github.com/raysan5/raylib/blob/master/examples/shaders/shaders_basic_lighting.c) to Zig
using [raylib-zig](https://github.com/Not-Nik/raylib-zig)

To run
==

```sh 
zig build run

zig build points --release=fast

zig build --release=safe -- -mmacosx-version-min=10.9 -framework AppKit
mv zig-out/bin/points MyApp.app/Contents/MacOS/MyApp
```