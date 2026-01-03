const std = @import("std");

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    defer _ = debug_allocator.deinit();
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-4/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    var width: usize = 0;
    var height: usize = 0;
    while (try reader.takeDelimiter('\n')) |line| : (height += 1) {
        if (width == 0) {
            width = line.len;
            continue;
        }

        if (width != line.len) {
            unreachable;
        }
    }
    try file_reader.seekTo(0);

    const paper_rolls = try allocator.alloc([]u8, height);
    defer allocator.free(paper_rolls);

    var row_counter: usize = 0;
    while (try reader.takeDelimiter('\n')) |line| : (row_counter += 1) {
        paper_rolls[row_counter] = line;
    }
    try file_reader.seekTo(0);

    var count: usize = 0;
    for (0..height) |i| {
        for (0..width) |j| {
            if (paper_rolls[i][j] != '@') {
                continue;
            }

            var neighbors: usize = 0;

            const left: usize = if (j > 0) j - 1 else j;
            if (left != j and paper_rolls[i][left] == '@') {
                neighbors += 1;
            }
            const right = j + 1;
            if (right < width and paper_rolls[i][right] == '@') {
                neighbors += 1;
            }
            const top: usize = if (i > 0) i - 1 else i;
            if (top != i and paper_rolls[top][j] == '@') {
                neighbors += 1;
            }
            const bottom = i + 1;
            if (bottom < height and paper_rolls[bottom][j] == '@') {
                neighbors += 1;
            }

            if (left != j and top != i and paper_rolls[top][left] == '@') {
                neighbors += 1;
            }
            if (right < width and top != i and paper_rolls[top][right] == '@') {
                neighbors += 1;
            }
            if (left != j and bottom < height and paper_rolls[bottom][left] == '@') {
                neighbors += 1;
            }
            if (right < width and bottom < height and paper_rolls[bottom][right] == '@') {
                neighbors += 1;
            }

            if (neighbors < 4) {
                count += 1;
            }
        }
    }

    std.debug.print("{}\n", .{count});

    var total_removed_count: usize = 0;
    while (true) {
        const paper_rolls_copy = try allocator.alloc([]u8, height);
        defer {
            for (paper_rolls_copy) |line| {
                allocator.free(line);
            }
            allocator.free(paper_rolls_copy);
        }
        for (0..height) |i| {
            paper_rolls_copy[i] = try allocator.dupe(u8, paper_rolls[i]);
        }

        var removed_count: usize = 0;
        for (0..height) |i| {
            for (0..width) |j| {
                if (paper_rolls_copy[i][j] != '@') {
                    continue;
                }

                var neighbors: usize = 0;

                const left: usize = if (j > 0) j - 1 else j;
                if (left != j and paper_rolls_copy[i][left] == '@') {
                    neighbors += 1;
                }
                const right = j + 1;
                if (right < width and paper_rolls_copy[i][right] == '@') {
                    neighbors += 1;
                }
                const top: usize = if (i > 0) i - 1 else i;
                if (top != i and paper_rolls_copy[top][j] == '@') {
                    neighbors += 1;
                }
                const bottom = i + 1;
                if (bottom < height and paper_rolls_copy[bottom][j] == '@') {
                    neighbors += 1;
                }

                if (left != j and top != i and paper_rolls_copy[top][left] == '@') {
                    neighbors += 1;
                }
                if (right < width and top != i and paper_rolls_copy[top][right] == '@') {
                    neighbors += 1;
                }
                if (left != j and bottom < height and paper_rolls_copy[bottom][left] == '@') {
                    neighbors += 1;
                }
                if (right < width and bottom < height and paper_rolls_copy[bottom][right] == '@') {
                    neighbors += 1;
                }

                if (neighbors < 4) {
                    paper_rolls[i][j] = '.';
                    removed_count += 1;
                }
            }
        }

        if (removed_count > 0) {
            total_removed_count += removed_count;
            continue;
        }

        break;
    }

    std.debug.print("{}\n", .{total_removed_count});
}
