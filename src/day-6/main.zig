const std = @import("std");

const MathOperation = enum {
    @"+",
    @"*",
};

const MathProblem = struct {
    numbers_horizontal: std.ArrayList(u64),
    numbers_vertical: std.ArrayList(u64),
    line_segments: std.ArrayList([]u8),
    width: usize,
    operation: ?MathOperation,
};

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-6/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    var problems = try std.ArrayList(MathProblem).initCapacity(allocator, 0);
    defer problems.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |line| {
        var token_iterator = std.mem.tokenizeScalar(u8, line, ' ');
        var problem_index: usize = 0;
        while (token_iterator.next()) |token| : (problem_index += 1) {
            if (problems.items.len <= problem_index) {
                try problems.append(allocator, .{
                    .numbers_horizontal = try std.ArrayList(u64).initCapacity(allocator, 0),
                    .numbers_vertical = try std.ArrayList(u64).initCapacity(allocator, 0),
                    .line_segments = try std.ArrayList([]u8).initCapacity(allocator, 0),
                    .width = 0,
                    .operation = null,
                });
            }

            const operation = std.meta.stringToEnum(MathOperation, token);
            if (operation != null) {
                problems.items[problem_index].operation = operation;
            } else {
                const number = try std.fmt.parseInt(u64, token, 10);
                if (token.len > problems.items[problem_index].width) {
                    problems.items[problem_index].width = token.len;
                }
                try problems.items[problem_index].numbers_horizontal.append(allocator, number);
            }
        }
    }

    var total_sum: u64 = 0;

    for (problems.items) |problem| {
        var problem_sum: u64 = switch (problem.operation.?) {
            .@"+" => 0,
            .@"*" => 1,
        };

        for (problem.numbers_horizontal.items) |number| {
            switch (problem.operation.?) {
                .@"+" => problem_sum += number,
                .@"*" => problem_sum *= number,
            }
        }

        total_sum += problem_sum;
    }

    std.debug.print("Total horizontal sum of all problems: {}\n", .{total_sum});

    try file_reader.seekTo(0);

    while (try reader.takeDelimiter('\n')) |line| {
        var line_position: usize = 0;

        for (problems.items, 0..) |problem, i| {
            const line_segment = line[line_position .. line_position + problem.width];
            line_position += problem.width + 1;

            const trimmed_line_segment = std.mem.trim(u8, line_segment, " ");
            _ = std.fmt.parseInt(u64, trimmed_line_segment, 10) catch continue;

            try problems.items[i].line_segments.append(allocator, line_segment);
        }
    }

    for (problems.items, 0..) |problem, i| {
        for (0..problem.width) |j| {
            var column = try allocator.alloc(u8, problem.line_segments.items.len);
            defer allocator.free(column);

            for (problem.line_segments.items, 0..) |line_segment, k| {
                column[k] = line_segment[j];
            }

            const number = try std.fmt.parseInt(u64, std.mem.trim(u8, column, " "), 10);

            try problems.items[i].numbers_vertical.append(allocator, number);
        }
    }

    total_sum = 0;

    for (problems.items) |problem| {
        var problem_sum: u64 = switch (problem.operation.?) {
            .@"+" => 0,
            .@"*" => 1,
        };

        for (problem.numbers_vertical.items) |number| {
            switch (problem.operation.?) {
                .@"+" => problem_sum += number,
                .@"*" => problem_sum *= number,
            }
        }

        total_sum += problem_sum;
    }

    std.debug.print("Total vertical sum of all problems: {}\n", .{total_sum});
}
