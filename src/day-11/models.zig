const std = @import("std");

pub const Node = struct {
    id: [3]u8,

    pub fn init(id: []const u8) Node {
        return .{ .id = id[0..3].* };
    }

    pub fn eql(self: Node, other: Node) bool {
        return std.mem.eql(u8, &self.id, &other.id);
    }
};

pub const Graph = struct {
    allocator: std.mem.Allocator,
    edges: std.AutoHashMap(Node, []Node),

    pub fn init(allocator: std.mem.Allocator) Graph {
        return .{
            .allocator = allocator,
            .edges = std.AutoHashMap(Node, []Node).init(allocator),
        };
    }

    pub fn deinit(self: *Graph) void {
        var value_iterator = self.edges.valueIterator();
        while (value_iterator.next()) |nodes| {
            self.allocator.free(nodes.*);
        }
        self.edges.deinit();
    }

    pub fn add_edges(self: *Graph, start_node: Node, end_nodes: []Node) !void {
        try self.edges.put(start_node, end_nodes);
    }
};
