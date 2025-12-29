const std = @import("std");

const Tile = struct {
    x: u64,
    y: u64,

    pub fn init(x: u64, y: u64) Tile {
        return .{
            .x = x,
            .y = y,
        };
    }

    pub fn area(self: Tile, other: Tile) u64 {
        const dx = @max(self.x, other.x) - @min(self.x, other.x) + 1;
        const dy = @max(self.y, other.y) - @min(self.y, other.y) + 1;

        return dx * dy;
    }
};

const TileColor = enum {
    Red,
    Green,
    Outside,
};

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-9/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    var tiles = try std.ArrayList(Tile).initCapacity(allocator, 0);
    defer tiles.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |line| {
        var split_iterator = std.mem.splitScalar(u8, line, ',');

        const x = try std.fmt.parseInt(u64, split_iterator.next().?, 10);
        const y = try std.fmt.parseInt(u64, split_iterator.next().?, 10);

        try tiles.append(allocator, Tile.init(x, y));
    }

    var areas = try std.ArrayList(u64).initCapacity(allocator, 0);
    defer areas.deinit(allocator);

    for (0..tiles.items.len) |i| {
        for (i + 1..tiles.items.len) |j| {
            try areas.append(allocator, tiles.items[i].area(tiles.items[j]));
        }
    }

    std.mem.sort(u64, areas.items, {}, std.sort.asc(u64));
    std.debug.print("Max area between 2 red tiles is {}\n", .{areas.getLast()});

    var all_x = try std.ArrayList(u64).initCapacity(allocator, tiles.capacity);
    defer all_x.deinit(allocator);
    var all_y = try std.ArrayList(u64).initCapacity(allocator, tiles.capacity);
    defer all_y.deinit(allocator);

    for (tiles.items) |tile| {
        all_x.appendAssumeCapacity(tile.x);
        all_y.appendAssumeCapacity(tile.y);
    }

    std.mem.sort(u64, all_x.items, {}, std.sort.asc(u64));
    std.mem.sort(u64, all_y.items, {}, std.sort.asc(u64));

    var unique_x = try std.ArrayList(u64).initCapacity(allocator, all_x.items.len);
    defer unique_x.deinit(allocator);
    for (all_x.items) |x| {
        if (unique_x.items.len == 0 or unique_x.getLast() != x) {
            unique_x.appendAssumeCapacity(x);
        }
    }

    var unique_y = try std.ArrayList(u64).initCapacity(allocator, all_y.items.len);
    defer unique_y.deinit(allocator);
    for (all_y.items) |y| {
        if (unique_y.items.len == 0 or unique_y.getLast() != y) {
            unique_y.appendAssumeCapacity(y);
        }
    }

    var mapping_x = std.AutoHashMap(u64, usize).init(allocator);
    defer mapping_x.deinit();

    for (unique_x.items, 0..) |x, i| {
        try mapping_x.put(x, i);
    }

    var mapping_y = std.AutoHashMap(u64, usize).init(allocator);
    defer mapping_y.deinit();

    for (unique_y.items, 0..) |y, i| {
        try mapping_y.put(y, i);
    }

    const tile_matrix = try allocator.alloc([]?TileColor, unique_x.items.len);
    for (0..unique_x.items.len) |x| {
        tile_matrix[x] = try allocator.alloc(?TileColor, unique_y.items.len);
        @memset(tile_matrix[x], null);
    }
    defer {
        for (tile_matrix) |column| allocator.free(column);
        allocator.free(tile_matrix);
    }

    for (tiles.items, 0..) |tile, i| {
        const current_x = mapping_x.get(tile.x).?;
        const current_y = mapping_y.get(tile.y).?;

        tile_matrix[current_x][current_y] = .Red;

        const next_x = if (i < tiles.items.len - 1) mapping_x.get(tiles.items[i + 1].x).? else mapping_x.get(tiles.items[0].x).?;
        const next_y = if (i < tiles.items.len - 1) mapping_y.get(tiles.items[i + 1].y).? else mapping_y.get(tiles.items[0].y).?;

        if (current_x == next_x) {
            for (@min(current_y + 1, next_y + 1)..@max(current_y, next_y)) |y| {
                tile_matrix[current_x][y] = .Green;
            }
        }

        if (current_y == next_y) {
            for (@min(current_x + 1, next_x + 1)..@max(current_x, next_x)) |x| {
                tile_matrix[x][current_y] = .Green;
            }
        }
    }

    var queue = try std.ArrayList(Tile).initCapacity(allocator, unique_x.items.len * unique_y.items.len);
    defer queue.deinit(allocator);

    for (0..unique_x.items.len) |x| {
        if (tile_matrix[x][0] == null) {
            tile_matrix[x][0] = .Outside;
            try queue.append(allocator, Tile.init(x, 0));
        }
        if (tile_matrix[x][unique_y.items.len - 1] == null) {
            tile_matrix[x][unique_y.items.len - 1] = .Outside;
            try queue.append(allocator, Tile.init(x, unique_y.items.len - 1));
        }
    }

    for (0..unique_y.items.len) |y| {
        if (tile_matrix[0][y] == null) {
            tile_matrix[0][y] = .Outside;
            try queue.append(allocator, Tile.init(0, y));
        }
        if (tile_matrix[unique_x.items.len - 1][y] == null) {
            tile_matrix[unique_x.items.len - 1][y] = .Outside;
            try queue.append(allocator, Tile.init(unique_x.items.len - 1, y));
        }
    }

    while (queue.items.len > 0) {
        const current = queue.orderedRemove(0);
        const x = current.x;
        const y = current.y;

        if (y > 0) {
            const neighbor_y = y - 1;
            if (tile_matrix[x][neighbor_y] == null) {
                tile_matrix[x][neighbor_y] = .Outside;
                try queue.append(allocator, Tile.init(x, neighbor_y));
            }
        }

        if (y < unique_y.items.len - 1) {
            const neighbor_y = y + 1;
            if (tile_matrix[x][neighbor_y] == null) {
                tile_matrix[x][neighbor_y] = .Outside;
                try queue.append(allocator, Tile.init(x, neighbor_y));
            }
        }

        if (x > 0) {
            const neighbor_x = x - 1;
            if (tile_matrix[neighbor_x][y] == null) {
                tile_matrix[neighbor_x][y] = .Outside;
                try queue.append(allocator, Tile.init(neighbor_x, y));
            }
        }

        if (x < unique_x.items.len - 1) {
            const neighbor_x = x + 1;
            if (tile_matrix[neighbor_x][y] == null) {
                tile_matrix[neighbor_x][y] = .Outside;
                try queue.append(allocator, Tile.init(neighbor_x, y));
            }
        }
    }

    for (0..unique_x.items.len) |x| {
        for (0..unique_y.items.len) |y| {
            if (tile_matrix[x][y] == null) {
                tile_matrix[x][y] = .Green;
            }
        }
    }

    var valid_areas = try std.ArrayList(u64).initCapacity(allocator, 0);
    defer valid_areas.deinit(allocator);

    for (0..tiles.items.len) |i| {
        for (i + 1..tiles.items.len) |j| {
            const tile_i = tiles.items[i];
            const tile_j = tiles.items[j];

            const min_x = @min(mapping_x.get(tile_i.x).?, mapping_x.get(tile_j.x).?);
            const max_x = @max(mapping_x.get(tile_i.x).?, mapping_x.get(tile_j.x).?);
            const min_y = @min(mapping_y.get(tile_i.y).?, mapping_y.get(tile_j.y).?);
            const max_y = @max(mapping_y.get(tile_i.y).?, mapping_y.get(tile_j.y).?);

            var all_enclosed = true;
            outer: for (min_x..max_x + 1) |x| {
                for (min_y..max_y + 1) |y| {
                    if (tile_matrix[x][y] == .Outside) {
                        all_enclosed = false;
                        break :outer;
                    }
                }
            }

            if (all_enclosed) {
                try valid_areas.append(allocator, tile_i.area(tile_j));
            }
        }
    }

    std.mem.sort(u64, valid_areas.items, {}, std.sort.asc(u64));
    std.debug.print("Max area between 2 red tiles fully covered by red or green tiles is {}\n", .{valid_areas.getLast()});
}
