const std = @import("std");
const zui = @import("zui");
const rl = @cImport({
    @cInclude("raylib.h");
});

const Painter = struct {
    label: [*c]const u8 = "",
    box: bool = false,
    pub fn measure_content_fn(_: *@This()) [2]i32 {
        return .{ 0, 0 };
    }
    pub fn wrap_content_fn(_: *@This(), _: i32) i32 {
        return 0;
    }
};

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const ui = zui.Builder.Builder(Painter, .{});

    const root = comptime ui.node("col gap-10 p-10 w-400 h-300", .{ .box = true }, &.{
        ui.node("row gap-10 grow-x", .{}, &.{
            ui.leaf("w-120 h-50", .{ .box = true, .label = "btn-a" }),
            ui.leaf("w-120 h-50", .{ .box = true, .label = "btn-b" }),
        }),
        ui.node("row gap-10 grow-x", .{}, &.{
            ui.leaf("grow h-200", .{ .box = true, .label = "canvas" }),
            ui.leaf("w-150 h-200", .{ .box = true, .label = "sidebar" }),
        }),
    });

    const nodes = ui.build(root);

    var tree: zui.Ui.Tree(Painter, .{}) = .{};
    tree.init(alloc);
    defer tree.deinit();

    try tree.nodes.appendSlice(&nodes);
    try tree.compute(0);

    rl.InitWindow(800, 600, "hello raylib");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.RAYWHITE);
        for (tree.commands.items) |cmd| {
            const x: c_int = @intCast(cmd.x);
            const y: c_int = @intCast(cmd.y);
            const w: c_int = @intCast(cmd.w);
            const h: c_int = @intCast(cmd.h);
            if (cmd.painter.box) {
                rl.DrawRectangleLines(x, y, w, h, rl.RED);
            }
            rl.DrawText(cmd.painter.label, x, y, 20, rl.DARKGRAY);
        }
    }
}
