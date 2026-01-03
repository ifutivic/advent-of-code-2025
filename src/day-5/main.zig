const std = @import("std");

const NumberRange = struct {
    lower: u64,
    upper: u64,
};

const ReadingMode = enum { Ranges, IDs };

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-5/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    var reading_mode: ReadingMode = .Ranges;

    var ranges = try std.ArrayList(NumberRange).initCapacity(allocator, 0);
    defer ranges.deinit(allocator);
    var ids = try std.ArrayList(u64).initCapacity(allocator, 0);
    defer ids.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |line| {
        if (std.mem.eql(u8, line, "")) {
            reading_mode = .IDs;
            continue;
        }

        switch (reading_mode) {
            .Ranges => {
                var iterator = std.mem.splitScalar(u8, line, '-');
                const lower = try std.fmt.parseInt(u64, iterator.next().?, 10);
                const upper = try std.fmt.parseInt(u64, iterator.next().?, 10);
                try ranges.append(allocator, .{ .lower = lower, .upper = upper });
            },
            .IDs => {
                const id = try std.fmt.parseInt(u64, line, 10);
                try ids.append(allocator, id);
            },
        }
    }

    var fresh_items: u64 = 0;

    for (ids.items) |id| {
        var in_any_range = false;

        for (ranges.items) |range| {
            if (id >= range.lower and id <= range.upper) {
                in_any_range = true;
                break;
            }
        }

        fresh_items += if (in_any_range) 1 else 0;
    }

    std.debug.print("Fresh items in ranges: {}\n", .{fresh_items});

    std.mem.sort(NumberRange, ranges.items, {}, struct {
        fn lessThan(_: void, lhs: NumberRange, rhs: NumberRange) bool {
            return lhs.lower < rhs.lower;
        }
    }.lessThan);

    var merged_ranges = try std.ArrayList(NumberRange).initCapacity(allocator, ranges.capacity);
    defer merged_ranges.deinit(allocator);

    for (ranges.items) |range| {
        if (merged_ranges.items.len == 0) {
            try merged_ranges.append(allocator, range);
            continue;
        }

        if (range.lower <= merged_ranges.getLast().upper) {
            merged_ranges.items[merged_ranges.items.len - 1].upper = @max(range.upper, merged_ranges.getLast().upper);
        } else {
            try merged_ranges.append(allocator, range);
        }
    }

    var possible_fresh_items: u64 = 0;

    for (merged_ranges.items) |range| {
        possible_fresh_items += (range.upper - range.lower + 1);
    }

    std.debug.print("Possible fresh item IDs in ranges: {}\n", .{possible_fresh_items});
}
