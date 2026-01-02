const std = @import("std");
const Node = @import("models.zig").Node;
const Graph = @import("models.zig").Graph;

const State = struct {
    node: Node,
    visited_first: bool,
    visited_second: bool,
};

pub fn solvePart2(
    graph: Graph,
    start: Node,
    end: Node,
    first_node: Node,
    second_node: Node,
    allocator: std.mem.Allocator,
) !usize {
    var cache = std.AutoHashMap(State, usize).init(allocator);
    defer cache.deinit();

    const visited_first = start.eql(first_node);
    const visited_second = start.eql(second_node);

    return try searchGraph(
        graph,
        start,
        end,
        first_node,
        second_node,
        visited_first,
        visited_second,
        &cache,
        allocator,
    );
}

fn searchGraph(
    graph: Graph,
    current: Node,
    target: Node,
    first_node: Node,
    second_node: Node,
    visited_first: bool,
    visited_second: bool,
    cache: *std.AutoHashMap(State, usize),
    allocator: std.mem.Allocator,
) !usize {
    if (Node.eql(current, target)) {
        return if (visited_first and visited_second) 1 else 0;
    }

    var paths_count: usize = 0;

    const next_visited_first = visited_first or Node.eql(current, first_node);
    const next_visited_second = visited_second or Node.eql(current, second_node);

    if (graph.edges.get(current)) |neighbors| {
        for (neighbors) |neighbor| {
            const state = State{
                .node = neighbor,
                .visited_first = next_visited_first,
                .visited_second = next_visited_second,
            };

            if (cache.get(state)) |cached_count| {
                paths_count += cached_count;
            } else {
                const result = try searchGraph(
                    graph,
                    neighbor,
                    target,
                    first_node,
                    second_node,
                    next_visited_first,
                    next_visited_second,
                    cache,
                    allocator,
                );
                paths_count += result;
                try cache.put(state, result);
            }
        }
    }

    return paths_count;
}
