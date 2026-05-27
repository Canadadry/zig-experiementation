const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");

pub fn main(init: std.process.Init) !void {
    run(init) catch |err| {
        std.debug.print("failed {}\n", .{err});
        std.process.exit(1);
    };
}

fn run(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    const args = try init.minimal.args.toSlice(alloc);
    if (args.len != 2) {
        std.debug.print("expect 1 argument\n", .{});
        return error.missingCliArguments;
    }

    var l = lexer.Lexer.init(args[1]);
    var p = try parser.Parser.init(alloc, &l);
    defer p.deinit();
    const node = try p.parse();
    std.debug.print("{}\n", .{node.eval()});
}
