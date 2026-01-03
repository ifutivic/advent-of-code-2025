const std = @import("std");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = std.heap.DebugAllocator(.{}).init;
    defer _ = debug_allocator.deinit();
    const allocator: std.mem.Allocator = debug_allocator.allocator();

    const file: std.fs.File = try std.fs.cwd().openFile("src/day-2/input.txt", .{});
    defer file.close();

    const file_size: u64 = (try file.stat()).size;
    const buffer: []u8 = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader: std.fs.File.Reader = file.reader(buffer);
    var reader: *std.Io.Reader = &file_reader.interface;

    var total_patterns_size_two: usize = 0;
    var total_patterns: usize = 0;

    while (try reader.takeDelimiter(',')) |line| {
        const trimmed_line: []const u8 = std.mem.trimEnd(u8, line, "\n");

        var interator: std.mem.SplitIterator(u8, .scalar) = std.mem.splitScalar(u8, trimmed_line, '-');
        const lower_range: usize = try std.fmt.parseInt(usize, interator.next().?, 10);
        const upper_range: usize = try std.fmt.parseInt(usize, interator.next().?, 10);

        for (lower_range..upper_range + 1) |i| {
            var buf: [32]u8 = undefined;
            const digits: []u8 = try std.fmt.bufPrint(&buf, "{}", .{i});

            var pattern_size: usize = digits.len / 2;
            if (digits.len % 2 == 0 and std.mem.eql(u8, digits[0..pattern_size], digits[pattern_size .. 2 * pattern_size])) {
                total_patterns_size_two += try std.fmt.parseInt(usize, digits, 10);
            }

            for (2..digits.len + 1) |pattern_count| {
                if (digits.len % pattern_count != 0) {
                    continue;
                }

                pattern_size = digits.len / pattern_count;
                var pattern_valid: bool = true;
                for (0..pattern_count - 1) |j| {
                    if (!std.mem.eql(u8, digits[j * pattern_size .. (j + 1) * pattern_size], digits[(j + 1) * pattern_size .. (j + 2) * pattern_size])) {
                        pattern_valid = false;
                        break;
                    }
                }

                if (pattern_valid) {
                    total_patterns += try std.fmt.parseInt(usize, digits, 10);
                    break;
                }
            }
        }
    }

    std.debug.print("{}, {}\n", .{ total_patterns_size_two, total_patterns });
}
