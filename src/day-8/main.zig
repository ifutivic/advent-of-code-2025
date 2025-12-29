const std = @import("std");

const Network = struct {
    id: u64,
    size: u64,

    var last_id: u64 = 0;

    pub fn init(self: *Network) void {
        last_id += 1;
        self.id = last_id;
        self.size = 0;
    }

    pub fn increase_size(self: *Network) void {
        self.size += 1;
    }
};

const JunctionBox = struct {
    x: u64,
    y: u64,
    z: u64,

    network: ?*Network,

    pub fn init(x: u64, y: u64, z: u64) JunctionBox {
        return JunctionBox{
            .x = x,
            .y = y,
            .z = z,
            .network = null,
        };
    }

    pub fn distance(self: JunctionBox, other: JunctionBox) f64 {
        const dx = @max(self.x, other.x) - @min(self.x, other.x);
        const dy = @max(self.y, other.y) - @min(self.y, other.y);
        const dz = @max(self.z, other.z) - @min(self.z, other.z);

        return std.math.sqrt(@as(f64, @floatFromInt(dx * dx + dy * dy + dz * dz)));
    }

    pub fn connectable(self: JunctionBox, other: JunctionBox) bool {
        if (self.network == null or other.network == null) {
            return true;
        }

        return self.network != other.network;
    }

    pub fn connect(
        self: *JunctionBox,
        other: *JunctionBox,
        boxes: []JunctionBox,
        allocator: std.mem.Allocator,
    ) !*Network {
        if (self.network == null and other.network == null) {
            var network = try allocator.create(Network);
            network.init();

            self.network = network;
            network.increase_size();

            other.network = network;
            network.increase_size();

            return network;
        }

        if (self.network == null) {
            self.network = other.network;
            other.network.?.increase_size();
            return other.network.?;
        }

        if (other.network == null) {
            other.network = self.network;
            self.network.?.increase_size();
            return self.network.?;
        }

        if (self.network == other.network) {
            return error.BoxesAlreadyConnected;
        }

        const keep = self.network.?;
        const drop = other.network.?;

        for (boxes) |*box| {
            if (box.network == drop) {
                box.network = keep;
                keep.increase_size();
            }
        }

        allocator.destroy(drop);
        return keep;
    }
};

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-8/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    var boxes = try std.ArrayList(JunctionBox).initCapacity(allocator, 0);
    defer boxes.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |line| {
        var split_iterator = std.mem.splitScalar(u8, line, ',');

        const x = try std.fmt.parseInt(u64, split_iterator.next().?, 10);
        const y = try std.fmt.parseInt(u64, split_iterator.next().?, 10);
        const z = try std.fmt.parseInt(u64, split_iterator.next().?, 10);

        try boxes.append(allocator, JunctionBox.init(
            x,
            y,
            z,
        ));
    }

    const pairs_to_connect: usize = 1000;

    const JunctionBoxPair = struct {
        i: usize,
        j: usize,
        distance: f64,
    };
    var pairs = try std.ArrayList(JunctionBoxPair).initCapacity(allocator, 0);
    defer pairs.deinit(allocator);

    for (0..boxes.items.len - 1) |i| {
        for (i + 1..boxes.items.len) |j| {
            try pairs.append(allocator, .{ .i = i, .j = j, .distance = boxes.items[i].distance(boxes.items[j]) });
        }
    }

    std.mem.sort(JunctionBoxPair, pairs.items, {}, struct {
        fn lessThan(_: void, lhs: JunctionBoxPair, rhs: JunctionBoxPair) bool {
            return lhs.distance < rhs.distance;
        }
    }.lessThan);

    for (pairs.items[0..pairs_to_connect]) |pair| {
        if (!boxes.items[pair.i].connectable(boxes.items[pair.j])) {
            continue;
        }

        _ = try boxes.items[pair.i].connect(&boxes.items[pair.j], boxes.items, allocator);
    }

    var connections = std.AutoHashMap(*Network, void).init(allocator);
    defer connections.deinit();

    for (boxes.items) |box| {
        if (box.network) |net| {
            try connections.put(net, {});
        }
    }

    var circuits = try std.ArrayList(u64).initCapacity(allocator, 0);
    defer circuits.deinit(allocator);

    var it = connections.iterator();
    while (it.next()) |entry| {
        try circuits.append(allocator, entry.key_ptr.*.size);
    }

    std.mem.sort(u64, circuits.items, {}, std.sort.desc(u64));

    var product: u64 = 1;
    for (circuits.items[0..3]) |circuit| {
        product *= circuit;
    }

    std.debug.print("Product of the 3 largest circuits is {}\n", .{product});

    var boxes_copy = try boxes.clone(allocator);
    defer boxes_copy.deinit(allocator);

    var last_xi: u64 = undefined;
    var last_xj: u64 = undefined;

    while (true) {
        var no_connections = true;
        for (pairs.items) |pair| {
            if (!boxes_copy.items[pair.i].connectable(boxes_copy.items[pair.j])) {
                continue;
            }

            _ = try boxes_copy.items[pair.i].connect(&boxes_copy.items[pair.j], boxes_copy.items, allocator);
            no_connections = false;
            last_xi = boxes_copy.items[pair.i].x;
            last_xj = boxes_copy.items[pair.j].x;
        }

        if (no_connections) {
            break;
        }
    }

    std.debug.print("Product of the coordinates of the 2 circuits which completed the final network is {}\n", .{last_xi * last_xj});
}
