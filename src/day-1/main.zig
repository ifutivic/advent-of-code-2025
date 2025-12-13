const std = @import("std");

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-1/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    var position: i32 = 50;
    var hits_zero_counter: u32 = 0;
    var crosses_zero_counter: u32 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        const direction = line[0];
        const count = try std.fmt.parseInt(i32, line[1..], 10);

        const old_position = position;
        const new_position = switch (direction) {
            'L' => position - count,
            'R' => position + count,
            else => position,
        };

        crosses_zero_counter += @abs(new_position) / 100;

        if (old_position > 0 and new_position < 0) {
            crosses_zero_counter += 1;
        }

        if (@mod(new_position, 100) == 0 and new_position != 0) {
            crosses_zero_counter -= 1;
        }

        position = @mod(new_position, 100);
        if (position == 0) {
            hits_zero_counter += 1;
        }
    }

    std.debug.print("hit zero {} times\n", .{hits_zero_counter});
    std.debug.print("crossed zero {} times\n", .{crosses_zero_counter});
    std.debug.print("hit and crossed zero {} times\n", .{hits_zero_counter + crosses_zero_counter});
}
