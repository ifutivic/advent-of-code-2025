const std = @import("std");
const Node = @import("models.zig").Node;
const Graph = @import("models.zig").Graph;

pub fn solvePart1(
    graph: Graph,
    start: Node,
    end: Node,
    allocator: std.mem.Allocator,
) !std.ArrayList([]Node) {
    var all_paths = try std.ArrayList([]Node).initCapacity(allocator, 0);
    var current_path = try std.ArrayList(Node).initCapacity(allocator, 0);
    defer current_path.deinit(allocator);

    try searchGraph(graph, start, end, &current_path, &all_paths, allocator);

    return all_paths;
}

fn searchGraph(
    graph: Graph,
    current: Node,
    target: Node,
    path: *std.ArrayList(Node),
    all_paths: *std.ArrayList([]Node),
    allocator: std.mem.Allocator,
) !void {
    try path.append(allocator, current);

    if (current.eql(target)) {
        try all_paths.append(allocator, try allocator.dupe(Node, path.items));
    } else {
        if (graph.edges.get(current)) |neighbors| {
            for (neighbors) |neighbor| {
                try searchGraph(graph, neighbor, target, path, all_paths, allocator);
            }
        }
    }

    _ = path.pop();
}
