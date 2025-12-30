const std = @import("std");

const IndicatorLights = struct {
    lights: []bool,
    cost: usize,

    pub fn init(lights: []bool, cost: usize) IndicatorLights {
        return .{ .lights = lights, .cost = cost };
    }

    pub fn pressButton(self: *IndicatorLights, button: ButtonSchematic) void {
        for (button.schematic) |light| {
            self.lights[light] = !self.lights[light];
        }
    }

    pub fn hash(self: IndicatorLights) u64 {
        var hasher = std.hash.Fnv1a_64.init();
        std.hash.autoHashStrat(&hasher, self.lights, .Deep);
        return hasher.final();
    }

    pub fn lessThan(_: void, lhs: IndicatorLights, rhs: IndicatorLights) std.math.Order {
        return std.math.order(lhs.cost, rhs.cost);
    }

    pub fn fromString(allocator: std.mem.Allocator, string: []const u8) !IndicatorLights {
        const trimmed_string = std.mem.trim(u8, string, "[]");
        var lights = try allocator.alloc(bool, trimmed_string.len);

        for (trimmed_string, 0..) |char, i| {
            lights[i] = switch (char) {
                '.' => false,
                '#' => true,
                else => unreachable,
            };
        }

        return .{ .lights = lights, .cost = 0 };
    }
};

const ButtonSchematic = struct {
    schematic: []usize,

    pub fn init(schematic: []usize) ButtonSchematic {
        return .{ .schematic = schematic };
    }

    pub fn fromString(allocator: std.mem.Allocator, string: []const u8) !ButtonSchematic {
        const trimmed_string = std.mem.trim(u8, string, "()");
        var split_iterator = std.mem.splitScalar(u8, trimmed_string, ',');
        var size: usize = 0;

        while (split_iterator.next()) |_| : (size += 1) continue;
        split_iterator.reset();

        var schematic = try allocator.alloc(usize, size);
        var i: usize = 0;
        while (split_iterator.next()) |buf| : (i += 1) {
            schematic[i] = try std.fmt.parseInt(usize, buf, 10);
        }

        return .{ .schematic = schematic };
    }
};

const JoltageCounter = struct {
    lights: []usize,

    pub fn init(lights: []usize) JoltageCounter {
        return .{ .lights = lights };
    }

    pub fn pressButton(self: *JoltageCounter, button: ButtonSchematic) void {
        for (button.schematic) |light| {
            self.lights[light] += 1;
        }
    }

    pub fn fromString(allocator: std.mem.Allocator, string: []const u8) !JoltageCounter {
        const trimmed_string = std.mem.trim(u8, string, "{}");
        var split_iterator = std.mem.splitScalar(u8, trimmed_string, ',');
        var size: usize = 0;

        while (split_iterator.next()) |_| : (size += 1) continue;
        split_iterator.reset();

        var lights = try allocator.alloc(usize, size);
        var i: usize = 0;
        while (split_iterator.next()) |buf| : (i += 1) {
            lights[i] = try std.fmt.parseInt(usize, buf, 10);
        }

        return .{ .lights = lights };
    }
};

const Machine = struct {
    indicator_lights: IndicatorLights,
    joltage_counter: JoltageCounter,
    button_schematics: []ButtonSchematic,

    pub fn init(indicator_lights: IndicatorLights, joltage_counter: JoltageCounter, button_schematics: []ButtonSchematic) Machine {
        return .{
            .indicator_lights = indicator_lights,
            .joltage_counter = joltage_counter,
            .button_schematics = button_schematics,
        };
    }
};

fn dijkstra(allocator: std.mem.Allocator, machine: Machine) !usize {
    const num_lights = machine.indicator_lights.lights.len;

    const start_lights = try allocator.alloc(bool, num_lights);
    defer allocator.free(start_lights);
    @memset(start_lights, false);

    const start_state = IndicatorLights.init(start_lights, 0);
    const end_state = machine.indicator_lights;

    var queue = std.PriorityQueue(IndicatorLights, void, IndicatorLights.lessThan).init(allocator, {});
    defer {
        while (queue.removeOrNull()) |current_state| {
            if (current_state.lights.ptr != start_state.lights.ptr) {
                allocator.free(current_state.lights);
            }
        }
        queue.deinit();
    }

    var visited = std.AutoHashMap(u64, void).init(allocator);
    defer visited.deinit();

    try queue.add(start_state);

    while (queue.removeOrNull()) |current_state| {
        defer if (current_state.lights.ptr != start_state.lights.ptr) allocator.free(current_state.lights);

        if (std.mem.eql(bool, current_state.lights, end_state.lights)) {
            return current_state.cost;
        }

        const current_state_hash = current_state.hash();

        if (visited.contains(current_state_hash)) {
            continue;
        }
        try visited.put(current_state_hash, {});

        for (machine.button_schematics) |button_schematic| {
            const next_lights = try allocator.alloc(bool, num_lights);
            errdefer allocator.free(next_lights);
            @memcpy(next_lights, current_state.lights);

            var next_state = IndicatorLights.init(next_lights, current_state.cost + 1);
            next_state.pressButton(button_schematic);

            if (!visited.contains(next_state.hash())) {
                try queue.add(next_state);
            } else {
                allocator.free(next_lights);
            }
        }
    }

    return error.SolutionNotFound;
}

fn solvePart2(_: std.mem.Allocator, _: Machine) !usize {
    return 0;
}

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();

    const file = try std.fs.cwd().openFile("src/day-10/input.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var file_reader = file.reader(buffer);
    var reader = &file_reader.interface;

    var machines = try std.ArrayList(Machine).initCapacity(allocator, 0);
    defer {
        for (machines.items) |machine| {
            allocator.free(machine.indicator_lights.lights);
            for (machine.button_schematics) |button_schematic| {
                allocator.free(button_schematic.schematic);
            }
            allocator.free(machine.button_schematics);
        }
        machines.deinit(allocator);
    }

    while (try reader.takeDelimiter('\n')) |line| {
        var split_iterator = std.mem.splitScalar(u8, line, ' ');

        var size: usize = 0;
        while (split_iterator.next()) |_| : (size += 1) continue;
        split_iterator.reset();

        const indicator_lights = try IndicatorLights.fromString(allocator, split_iterator.next().?);

        var button_schematics = try allocator.alloc(ButtonSchematic, size - 2);
        for (0..size - 2) |i| {
            button_schematics[i] = try ButtonSchematic.fromString(allocator, split_iterator.next().?);
        }

        const joltage_counter = try JoltageCounter.fromString(allocator, split_iterator.next().?);

        const machine = Machine.init(indicator_lights, joltage_counter, button_schematics);

        try machines.append(allocator, machine);
    }

    var total_presses: usize = 0;
    for (machines.items) |machine| {
        total_presses += try dijkstra(allocator, machine);
    }

    std.debug.print("Total presses to configure indicator lights: {}\n", .{total_presses});

    total_presses = 0;
    for (machines.items) |machine| {
        total_presses += try solvePart2(allocator, machine);
    }

    std.debug.print("Total presses to reach joltage requirements: {}\n", .{total_presses});
}
