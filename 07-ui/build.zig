const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "_07_ui",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const zui_dep = b.dependency("zui", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zui", zui_dep.module("zui"));

    exe.root_module.addIncludePath(b.path("vendor/raylib"));
    exe.root_module.link_libc = true;

    switch (target.result.os.tag) {
        .macos => {
            exe.root_module.addLibraryPath(b.path("vendor/raylib/macos"));
            exe.root_module.linkSystemLibrary("raylib", .{});
            exe.root_module.linkFramework("OpenGL", .{});
            exe.root_module.linkFramework("Cocoa", .{});
            exe.root_module.linkFramework("IOKit", .{});
            exe.root_module.linkFramework("CoreAudio", .{});
            exe.root_module.linkFramework("CoreVideo", .{});
        },
        .linux => {
            exe.root_module.addLibraryPath(b.path("vendor/raylib/linux"));
            exe.root_module.linkSystemLibrary("raylib", .{});
            const link_opts: std.Build.Module.LinkSystemLibraryOptions = .{
                .preferred_link_mode = .dynamic,
                .use_pkg_config = .no,
                .search_strategy = .no_fallback,
            };
            exe.root_module.linkSystemLibrary("GL", link_opts);
            exe.root_module.linkSystemLibrary("X11", link_opts);
            exe.root_module.linkSystemLibrary("pthread", link_opts);
            exe.root_module.linkSystemLibrary("m", link_opts);
            exe.root_module.linkSystemLibrary("dl", link_opts);
        },
        else => @panic("unsupported OS"),
    }

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
