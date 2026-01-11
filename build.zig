const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const total_days: usize = 12;

    inline for (1..total_days + 1) |i| {
        const day_prefix = "day-";
        const day_number = std.fmt.comptimePrint("{d}", .{i});
        const day = day_prefix ++ day_number;
        const path = "src/" ++ day ++ "/main.zig";

        const exe = b.addExecutable(.{
            .name = day,
            .root_module = b.createModule(.{
                .root_source_file = b.path(path),
                .target = target,
                .optimize = optimize,
            }),
        });
        b.installArtifact(exe);

        const build_cmd = b.addInstallArtifact(exe, .{});

        const build_step = b.step(day, std.fmt.comptimePrint("Build the code for AoC {s}", .{day}));
        build_step.dependOn(&build_cmd.step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.setCwd(b.path(""));

        const run_step = b.step("run-" ++ day, std.fmt.comptimePrint("Run the code for AoC {s}", .{day}));
        run_step.dependOn(&run_cmd.step);
    }
}
