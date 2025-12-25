const std = @import("std");

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-7/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    try reader.readSliceAll(buffer);
    try file_reader.seekTo(0);

    const line_count: usize = std.mem.count(u8, buffer, "\n");

    const beams = try allocator.alloc([]u8, line_count);
    defer allocator.free(beams);
    const timelines = try allocator.alloc([]?u64, line_count);
    defer allocator.free(timelines);

    var line_number: usize = 0;

    while (try reader.takeDelimiter('\n')) |line| : (line_number += 1) {
        beams[line_number] = line;
        timelines[line_number] = try allocator.alloc(?u64, line.len);
        @memset(timelines[line_number], null);
    }

    var split_counter: u64 = 0;

    for (beams[0 .. line_count - 1], 0..line_count - 1) |row, row_number| {
        for (row, 0..) |symbol, column_number| {
            switch (symbol) {
                'S' => {
                    beams[row_number + 1][column_number] = '|';
                    timelines[row_number + 1][column_number] = 1;
                },
                '|' => {
                    if (beams[row_number + 1][column_number] == '^') {
                        beams[row_number + 1][column_number + 1] = '|';
                        beams[row_number + 1][column_number - 1] = '|';

                        split_counter += 1;

                        const timeline_count = timelines[row_number][column_number].?;

                        if (timelines[row_number + 1][column_number + 1] == null) {
                            timelines[row_number + 1][column_number + 1] = timeline_count;
                        } else {
                            timelines[row_number + 1][column_number + 1].? += timeline_count;
                        }

                        if (timelines[row_number + 1][column_number - 1] == null) {
                            timelines[row_number + 1][column_number - 1] = timeline_count;
                        } else {
                            timelines[row_number + 1][column_number - 1].? += timeline_count;
                        }
                    } else {
                        beams[row_number + 1][column_number] = '|';

                        const timeline_count = timelines[row_number][column_number].?;

                        if (timelines[row_number + 1][column_number] == null) {
                            timelines[row_number + 1][column_number] = timeline_count;
                        } else {
                            timelines[row_number + 1][column_number].? += timeline_count;
                        }
                    }
                },
                else => continue,
            }
        }
    }

    std.debug.print("Tachyon beam split {} times\n", .{split_counter});

    var timeline_counter: u64 = 0;

    for (timelines[timelines.len - 1]) |timeline| {
        if (timeline == null) {
            continue;
        }

        timeline_counter += timeline.?;
    }

    std.debug.print("Tachyon beam exists in {} timelines\n", .{timeline_counter});
}
