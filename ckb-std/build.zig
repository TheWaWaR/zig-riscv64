const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("ckb-std", "src/ckb_std.zig");
    lib.addAssemblyFile("src/syscall.S");
    lib.setBuildMode(mode);
    lib.install();

    const lib_tests = b.addTest("src/ckb_std.zig");
    lib_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&lib_tests.step);
}
