const std = @import("std");

pub fn build(b: *std.Build) void {

	const exe = b.addExecutable(.{
		.name = "eval",
		.root_source_file = b.path("src/main.zig"),
		.target = b.host,
	});

    // const srcDir = "src";
    // addSourceFiles(b, exe, srcDir) catch {
    //     std.debug.warn("Erreur lors de l'ajout des fichiers sources: {}\n", .{srcDir});
    //     return;
    // };
    b.installArtifact(exe);
}

// fn addSourceFiles(b: *std.Build, exe: *std.Build.Step.Compile, path: []const u8) !void {
// 	var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
// 	var walker = try dir.walk(b.allocator);
// 	defer walker.deinit();
// 	while (try walker.next()) |entry| {
// 		if (entry.kind == .file and std.mem.endsWith(u8, entry.path, ".zig")) {
// 			exe.addPackagePath(entry.name, entry.path);
// 		}
// 	}
// }
