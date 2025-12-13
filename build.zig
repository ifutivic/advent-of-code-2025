const std = @import("std");

pub fn build(b: *std.Build) !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const total_days: usize = 4;

    for (1..total_days + 1) |i| {
        const day_number = try std.fmt.allocPrint(allocator, "{}", .{i});
        const day_prefix = "day-";

        const day = try std.mem.concat(allocator, u8, &.{ day_prefix, day_number });
        defer allocator.free(day);
        const path = try std.mem.concat(allocator, u8, &.{ "src/", day, "/main.zig" });
        defer allocator.free(path);

        const exe = b.addExecutable(.{
            .name = day,
            .root_module = b.createModule(.{
                .root_source_file = b.path(path),
                .target = target,
                .optimize = optimize,
            }),
        });

        b.installArtifact(exe);

        const run_step = b.step(day, "Run the app");
        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
    }
}
