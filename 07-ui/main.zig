const std = @import("std");
const zui = @import("zui");
const ztext = @import("ztext");
const rl = @cImport({
    @cInclude("raylib.h");
});

const FontPainter = struct {
    pub fn measure_rune(_: *const @This(), rune: u32, size: u32, font: rl.struct_Font) u32 {
        const index: usize = @intCast(font.GetGlyphIndex(@intCast(rune)));
        const scaleFactor = @as(f32, @floatFromInt(size)) / @as(f32, @floatFromInt(font.baseSize));
        var glyphWidth: f32 = 0;
        if (rune != '\n') {
            glyphWidth = @as(f32, @floatFromInt(font.glyphs[index].advanceX));
            if (glyphWidth == 0) {
                glyphWidth = font.recs[index].width;
            }
            glyphWidth *= scaleFactor;
        }
        return @intFromFloat(glyphWidth);
    }
    pub fn draw_rune(_: *@This(), x: u32, y: u32, cp: u32, size: u32, font: rl.struct_Font) void {
        rl.DrawTextCodepoint(
            font,
            @intCast(cp),
            .{ .x = @floatFromInt(x), .y = @floatFromInt(y) },
            @floatFromInt(size),
            rl.WHITE,
        );
    }
};

pub const Painter = union(enum) {
    none: struct {},
    rect: struct { color: rl.struct_Color },
    text: struct {
        len: usize,
        text: [255:0]u8,
        color: rl.struct_Color,
        font: ztext.Text.Font(FontPainter, .{}, rl.struct_Font, .{}),
    },
    img: rl.struct_Texture,
    pub fn measure_content_fn(self: *@This()) [2]i32 {
        return switch (self.*) {
            .none => .{ 0, 0 },
            .rect => .{ 0, 0 },
            .img => |i| .{ i.width, i.height },
            .text => |t| {
                const box = t.font.measureText(t.text[0..], 0);
                return .{ @intCast(box.x), @intCast(box.y) };
            },
        };
    }
    pub fn wrap_content_fn(self: *@This(), width: i32) i32 {
        return switch (self.*) {
            .none => 0,
            .rect => 0,
            .img => |i| @intFromFloat(
                @as(f32, @floatFromInt(width)) * @as(f32, @floatFromInt(i.height)) / @as(f32, @floatFromInt(i.width)),
            ),
            .text => |t| @intCast(t.font.measureText(t.text[0..], @intCast(width)).y),
        };
    }
    pub fn draw(self: *@This(), x: u32, y: u32, w: u32, h: u32) void {
        switch (self.*) {
            .none => {},
            .rect => |r| rl.DrawRectangle(@intCast(x), @intCast(y), @intCast(w), @intCast(h), r.color),
            .img => |i| rl.DrawTextureEx(i, .{ .x = @floatFromInt(x), .y = @floatFromInt(y) }, 0, 0, rl.WHITE),
            .text => |t| {
                t.font.draw(t.text[0..t.len], .{ .x = x, .y = y, .width = w, .height = h });
            },
        }
    }
};

pub const MultiPainter = struct {
    const max_painters = 8;
    count: usize = 0,
    items: [max_painters]Painter = undefined,

    pub fn from(comptime len: usize, painters: [len]Painter) @This() {
        comptime {
            if (len > max_painters) {
                @compileError("max painter on one node is " ++ max_painters);
            }
        }
        var mp: @This() = .{ .count = len };
        @memcpy(mp.items[0..len], &painters);
        return mp;
    }

    pub fn measure_content_fn(self: *@This()) [2]i32 {
        var max_size: [2]i32 = .{ 0, 0 };
        for (0..self.count) |i| {
            var p = self.items[i];
            const current = p.measure_content_fn();
            if (max_size[0] < current[0]) {
                max_size[0] = current[0];
            }
            if (max_size[1] < current[1]) {
                max_size[1] = current[1];
            }
        }
        return max_size;
    }

    pub fn wrap_content_fn(self: *@This(), width: i32) i32 {
        var max_height: i32 = 0;
        for (0..self.count) |i| {
            var p = self.items[i];
            const current = p.wrap_content_fn(width);
            if (max_height < current) {
                max_height = current;
            }
        }
        return max_height;
    }

    pub fn draw(self: *@This(), x: u32, y: u32, w: u32, h: u32) void {
        for (0..self.count) |i| {
            var p = self.items[i];
            p.draw(x, y, w, h);
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
    var p = Painter{
        .text = .{
            .len = txt.len,
            .text = std.mem.zeroes([255:0]u8),
            .color = rl.DARKGRAY,
            .font = ztext.Text.Font(FontPainter, .{}, rl.struct_Font, .{}){
                .size = 20,
                .spacing = 2,
                .familly = rl.GetFontDefault(),
                .@"align" = .{
                    .x = .middle,
                    .y = .middle,
                },
            },
        },
    };
    const len = @min(txt.len, 254);
    @memcpy(p.text.text[0..len], txt[0..len]);
    p.text.text[len] = 0;
    return p;
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    rl.InitWindow(800, 600, "hello raylib");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    const uib = zui.Builder.Builder(MultiPainter, .{});
    const from = MultiPainter.from;
    const root = uib.node("col gap-10 p-10 w-400 h-300", from(1, .{Rect(rl.RED)}), &.{
        uib.node("row gap-10 grow-x", from(1, .{Rect(rl.GREEN)}), &.{
            uib.leaf("w-120 h-50", from(2, .{ Rect(rl.YELLOW), Txt("btn-a") })),
            uib.leaf("w-120 h-50", from(2, .{ Rect(rl.YELLOW), Txt("btn-b") })),
        }),
        uib.node("row gap-10 grow-x", from(1, .{Rect(rl.BLUE)}), &.{
            uib.leaf("grow h-200", from(2, .{ Rect(rl.YELLOW), Txt("canvas") })),
            uib.leaf("w-150 h-200", from(2, .{ Rect(rl.YELLOW), Txt("sidebar") })),
        }),
    });

    var list = std.array_list.Managed(zui.Ui.Node(MultiPainter, .{})).init(alloc);
    defer list.deinit();
    try uib.build(root, &list);

    var tree: zui.Ui.Tree(MultiPainter, .{}) = .{};
    tree.init(alloc);
    defer tree.deinit();

    try tree.nodes.appendSlice(list.items);
    try tree.compute(0);

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.RAYWHITE);
        for (tree.commands.items) |*cmd| {
            const x: c_int = @intCast(cmd.x);
            const y: c_int = @intCast(cmd.y);
            const w: c_int = @intCast(cmd.w);
            const h: c_int = @intCast(cmd.h);
            cmd.painter.draw(@intCast(x), @intCast(y), @intCast(w), @intCast(h));
        }
    }
}
