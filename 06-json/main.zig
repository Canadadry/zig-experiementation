const std = @import("std");

const Place = struct { lat: f32, long: f32 };

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    const args = try init.minimal.args.toSlice(alloc);
    if (args.len != 2) {
        std.debug.print("expect 1 argument\n", .{});
        return error.missingCliArguments;
    }

    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(init.io, args[1], .{ .mode = .read_only });
    defer file.close(init.io);

    var read_buffer: [1024]u8 = undefined;
    var fr = file.reader(init.io, &read_buffer);
    const reader = &fr.interface;

    var json_reader = std.json.Reader.init(alloc, reader);

    const parsed = try std.json.parseFromTokenSource([]Place, alloc, &json_reader, .{});
    for (parsed.value) |p| {
        std.debug.print("{d}-{d}\n", .{ p.lat, p.long });
    }
}

test "json parse" {
    const parsed = try std.json.parseFromSlice(
        Place,
        std.testing.allocator,
        \\{ "lat": 40.684540, "long": -74.401422 }
    ,
        .{},
    );
    defer parsed.deinit();

    const place = parsed.value;

    try std.testing.expectEqual(place.lat, 40.684540);
    try std.testing.expectEqual(place.long, -74.401422);
}
