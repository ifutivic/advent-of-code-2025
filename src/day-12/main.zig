const std = @import("std");

pub fn main() !void {
    const input = @embedFile("input.txt");
    var line_iterator = std.mem.splitScalar(u8, input, '\n');

    var answer: usize = 0;

    while (line_iterator.next()) |line| {
        if (std.mem.containsAtLeastScalar(u8, line, 1, 'x')) {
            const colon_index = std.mem.indexOf(u8, line, ":").?;

            const dimensions_string = line[0..colon_index];
            const counts_string = line[colon_index + 1 ..];

            var dimensions_iterator = std.mem.splitScalar(u8, dimensions_string, 'x');
            const width = try std.fmt.parseInt(usize, dimensions_iterator.next().?, 10);
            const height = try std.fmt.parseInt(usize, dimensions_iterator.next().?, 10);

            var total_presents: usize = 0;
            var counts_iterator = std.mem.tokenizeScalar(u8, counts_string, ' ');
            while (counts_iterator.next()) |count_string| {
                total_presents += try std.fmt.parseInt(usize, count_string, 10);
            }

            if (3 * 3 * total_presents <= width * height) {
                answer += 1;
            }
        }
    }

    std.debug.print("{d}\n", .{answer});
}
