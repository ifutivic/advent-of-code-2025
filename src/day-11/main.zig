const std = @import("std");
const Node = @import("models.zig").Node;
const Graph = @import("models.zig").Graph;

const solvePart1 = @import("part-1.zig").solvePart1;
const solvePart2 = @import("part-2.zig").solvePart2;

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    var graph = Graph.init(allocator);
    defer graph.deinit();

    const input = @embedFile("input.txt");
    var line_iterator = std.mem.splitScalar(u8, input, '\n');

    while (line_iterator.next()) |line| {
        if (std.mem.eql(u8, line, "")) {
            continue;
        }

        const start_node_id = line[0..3];
        const end_node_ids = line[5..];

        const start_node = Node.init(start_node_id);
        const end_nodes = try allocator.alloc(Node, std.mem.count(u8, end_node_ids, " ") + 1);

        var node_id_iterator = std.mem.splitScalar(u8, end_node_ids, ' ');
        var i: usize = 0;

        while (node_id_iterator.next()) |node_id| : (i += 1) {
            end_nodes[i] = Node.init(node_id);
        }

        try graph.add_edges(start_node, end_nodes);
    }

    const you = Node.init("you");
    const out = Node.init("out");
    var paths_part_1 = try solvePart1(graph, you, out, allocator);
    defer {
        for (paths_part_1.items) |path| {
            allocator.free(path);
        }
        paths_part_1.deinit(allocator);
    }

    std.debug.print("Found {} paths between '{s}' and '{s}'\n", .{ paths_part_1.items.len, you.id, out.id });

    const svr = Node.init("svr");
    const fft = Node.init("fft");
    const dac = Node.init("dac");
    const paths_part_2 = try solvePart2(graph, svr, out, fft, dac, allocator);

    std.debug.print("Found {} paths between '{s}' and '{s}' which visit both '{s}' and '{s}'\n", .{ paths_part_2, svr.id, out.id, dac.id, fft.id });
}
