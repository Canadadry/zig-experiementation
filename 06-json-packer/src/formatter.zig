const std = @import("std");

pub fn format(
    allocator: std.mem.Allocator,
    reader: std.Io.Reader,
    writer: std.Io.Writer,
    line_width: usize,
) !void {
    _ = allocator;
    _ = reader;
    _ = writer;
    _ = line_width;
}

// test "stream" {
//     var out_buffer: [10]u8 = undefined;
//     var r: std.Io.Reader = .fixed("foobar");
//     var w: std.Io.Writer = .fixed(&out_buffer);
//     // Short streams are possible with this function but not with fixed.
//     try std.testing.expectEqual(2, try r.stream(&w, .limited(2)));
//     try std.testing.expectEqualStrings("fo", w.buffered());
//     try std.testing.expectEqual(4, try r.stream(&w, .unlimited));
//     try std.testing.expectEqualStrings("foobar", w.buffered());
// }

test "pretty-printed small flat object collapses to one line" {
    const input =
        \\{
        \\  "kind": "fixed",
        \\  "size": 100
        \\}
    ;
    const expected = "{\"kind\": \"fixed\", \"size\": 100}";
    var output: [255]u8 = @splat(0);

    const r: std.Io.Reader = .fixed(input);
    const w: std.Io.Writer = .fixed(output[0..]);

    try format(std.testing.allocator, r, w, 80);

    try std.testing.expectEqualStrings(expected, &output);
}
