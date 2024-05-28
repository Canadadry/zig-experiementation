const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");


pub fn main() !void{
	run() catch |err|{
		std.debug.print("failed {}\n",.{err});
		std.process.exit(1);
	};
}

fn run() !void{
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	defer _ = gpa.deinit();
	const alloc = gpa.allocator();
	const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

	if(args.len!=2){
		std.debug.print("expect 1 argument\n",.{});
		return error.missingCliArguments;
	}

	var l = lexer.Lexer.init(args[1]);
	var p = try parser.Parser.init(alloc,&l);
	defer p.deinit();
 	const node = try p.parse();
  	std.debug.print("{}\n",.{node.eval()});
}