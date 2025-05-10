const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "olog",
        .root_source_file = b.path("src/main.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    b.installArtifact(exe);

    const run_arti = b.addRunArtifact(exe);
    const run_step = b.step("run", "run olog");
    run_step.dependOn(&run_arti.step);

    const test_exe = b.addExecutable(.{
        .name = "test",
        .root_source_file = b.path("src/main.zig"),
        .target = b.graph.host,
    });
    b.installArtifact(test_exe);

    const test_arti = b.addRunArtifact(test_exe);
    const test_step = b.step("tests", "run unit tests");
    test_step.dependOn(&test_arti.step);
}
