const std = @import("std");

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-3/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    var sum_1: i64 = 0;
    var sum_2: i64 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        var first_digit: i64 = 0;
        var second_digit: i64 = 0;
        for (0..line.len) |i| {
            const digit = try std.fmt.parseInt(i64, line[i .. i + 1], 10);

            if (digit > first_digit and i != line.len - 1) {
                first_digit = digit;
                second_digit = 0;
                continue;
            }
            if (digit > second_digit) {
                second_digit = digit;
                continue;
            }
        }

        sum_1 += first_digit * 10 + second_digit;

        var selected_digits = std.mem.zeroes([12]i64);
        outer: for (0..line.len) |i| {
            const digit = try std.fmt.parseInt(i64, line[i .. i + 1], 10);

            for (0..selected_digits.len) |j| {
                if (digit > selected_digits[j] and (selected_digits.len - j) <= (line.len - i)) {
                    selected_digits[j] = digit;
                    for (j + 1..selected_digits.len) |k| {
                        selected_digits[k] = 0;
                    }
                    continue :outer;
                }
            }
        }

        for (selected_digits, 1..) |digit, i| {
            sum_2 += digit * std.math.pow(i64, 10, @intCast(selected_digits.len - i));
        }
    }

    std.debug.print("{} {}\n", .{ sum_1, sum_2 });
}
