const std = @import("std");
const zui = @import("zui");
const ztext = @import("ztext");
const rl = @cImport({
    @cInclude("raylib.h");
});

const FontPainter = struct {
    pub fn measure_rune(_: *const @This(), rune: u32, size: u32, font: rl.struct_Font) u32 {
        const index = font.GetGlyphIndex(rune);
        const scaleFactor = size / font.baseSize;
        var glyphWidth: f32 = 0;
        if (rune != '\n') {
            glyphWidth = font.glyphs[index].advanceX;
            if (glyphWidth == 0) {
                glyphWidth = font.recs[index].width;
            }
            glyphWidth *= scaleFactor;
        }
        return glyphWidth;
    }
    pub fn draw_rune(_: *@This(), x: u32, y: u32, cp: u32, size: u32, font: rl.struct_Font) void {
        rl.DrawTextCodepoint(font, cp, .{ .x = x, .y = y }, size, rl.WHITE);
    }
};

pub const Painter = union(enum) {
    none: struct {},
    rect: struct { color: rl.struct_Color },
    text: struct {
        text: [255:0]u8,
        color: rl.struct_Color,
        font: ztext.Text.Font(FontPainter, .{}, rl.struct_Font, .{}),
    },
    img: rl.struct_Texture,
    pub fn measure_content_fn(self: *@This()) [2]i32 {
        return switch (self) {
            .none => .{ 0, 0 },
            .rect => .{ 0, 0 },
            .img => |i| .{ i.width, i.height },
            .text => |t| {
                const box = t.font.measureText(t.text, 0);
                return .{ box.x, box.y };
            },
        };
    }
    pub fn wrap_content_fn(self: *@This(), width: i32) i32 {
        return switch (self) {
            .none => 0,
            .rect => 0,
            .img => |i| width * i.height / i.width,
            .text => |t| {
                t.font.measureText(t.text, width).y;
            },
        };
    }
    pub fn draw(self: *@This(), x: u32, y: u32, w: u32, h: u32) void {
        switch (self) {
            .none => {},
            .rect => |r| rl.DrawRectangle(x, y, w, h, r.color),
            .img => |i| rl.DrawTextureEx(i, .{ .x = x, .y = y }, 0, 0, rl.WHITE),
            .text => |t| {
                t.font.draw(t.text, .{ .x = x, .y = y, .width = w, .height = h });
            },
        }
    }
};

pub fn None() Painter {
    return Painter{ .none = .{} };
}

pub fn Rect(c: rl.struct_Color) Painter {
    return Painter{ .rect = .{ .color = c } };
}

pub fn Img(source: [:0]const u8) Painter {
    return Painter{
        .img = rl.LoadTexture(source),
    };
}

pub fn Txt(txt: [:0]const u8) Painter {
    var p = Painter{ .text = .{
        .text = std.mem.zeroes([255:0]u8),
        .font = rl.GetFontDefault(),
    } };
    const len = @min(txt.len, 254);
    @memcpy(p.text.text[0..len], txt[0..len]);
    p.text.text[len] = 0;
    return p;
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const ui = zui.Builder.Builder(Painter, Painter{ .none = .{} });

    const root = ui.node("col gap-10 p-10 w-400 h-300", Rect(rl.RED), &.{
        ui.node("row gap-10 grow-x", None(), &.{
            ui.leaf("w-120 h-50", Txt("btn-a")),
            ui.leaf("w-120 h-50", Txt("btn-b")),
        }),
        ui.node("row gap-10 grow-x", None(), &.{
            ui.leaf("grow h-200", Txt("canvas")),
            ui.leaf("w-150 h-200", Txt("sidebar")),
        }),
    });

    var list = std.array_list.Managed(ui.Node(Painter, Painter{ .none = .{} })).init(alloc);
    defer list.deinit();
    try ui.build(root, &list);

    var tree: zui.Ui.Tree(Painter, .{}) = .{};
    tree.init(alloc);
    defer tree.deinit();

    try tree.nodes.appendSlice(list.items);
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
            cmd.painter.draw(x, y, w, h);
        }
    }
}
