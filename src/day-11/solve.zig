const std = @import("std");
const Node = @import("models.zig").Node;
const Graph = @import("models.zig").Graph;

pub fn findAllPaths(allocator: std.mem.Allocator, graph: Graph, start: Node, end: Node) !usize {
    var cache = std.AutoHashMap(Node, usize).init(allocator);
    defer cache.deinit();

    return try findPathsRecursive(graph, start, end, &cache);
}

fn findPathsRecursive(graph: Graph, current: Node, target: Node, cache: *std.AutoHashMap(Node, usize)) !usize {
    if (Node.eql(current, target)) {
        return 1;
    }

    var total_paths: usize = 0;

    if (graph.edges.get(current)) |neighbors| {
        for (neighbors) |neighbor| {
            if (cache.get(neighbor)) |cached_paths| {
                total_paths += cached_paths;
            } else {
                const paths = try findPathsRecursive(graph, neighbor, target, cache);
                total_paths += paths;
                try cache.put(neighbor, paths);
            }
        }
    }

    return total_paths;
}
