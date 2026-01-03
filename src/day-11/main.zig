const std = @import("std");
const Node = @import("models.zig").Node;
const Graph = @import("models.zig").Graph;

const findAllPaths = @import("solve.zig").findAllPaths;

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
    const paths_you_out = try findAllPaths(allocator, graph, you, out);

    std.debug.print("Found {d} paths between '{s}' and '{s}'\n", .{ paths_you_out, you.id, out.id });

    const svr = Node.init("svr");
    const fft = Node.init("fft");
    const dac = Node.init("dac");

    const paths_svr_fft = try findAllPaths(allocator, graph, svr, fft);
    const paths_fft_dac = try findAllPaths(allocator, graph, fft, dac);
    const paths_dac_out = try findAllPaths(allocator, graph, dac, out);

    const paths_svr_dac = try findAllPaths(allocator, graph, svr, dac);
    const paths_dac_fft = try findAllPaths(allocator, graph, dac, fft);
    const paths_fft_out = try findAllPaths(allocator, graph, fft, out);

    const total_paths = paths_svr_fft * paths_fft_dac * paths_dac_out + paths_svr_dac * paths_dac_fft * paths_fft_out;

    std.debug.print("Found {d} paths between '{s}' and '{s}' which visit both '{s}' and '{s}'\n", .{ total_paths, svr.id, out.id, dac.id, fft.id });
}
