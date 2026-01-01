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

    pub fn hash(self: JoltageCounter) u64 {
        var hasher = std.hash.Fnv1a_64.init();
        std.hash.autoHashStrat(&hasher, self.lights, .Deep);
        return hasher.final();
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

fn solvePart1(allocator: std.mem.Allocator, machine: Machine) !usize {
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

fn recursive(
    allocator: std.mem.Allocator,
    machine: Machine,
    joltage_counter: JoltageCounter,
    button_combo_cache: *std.AutoHashMap(u64, std.ArrayList([]usize)),
    joltage_cache: *std.AutoHashMap(u64, usize),
) !usize {
    if (std.mem.allEqual(u64, joltage_counter.lights, 0)) return 0;

    const joltage_cache_key = joltage_counter.hash();
    if (joltage_cache.get(joltage_cache_key)) |cached| {
        return cached;
    }

    var min_presses: usize = std.math.maxInt(usize);

    var target_indicator_lights = try allocator.alloc(bool, joltage_counter.lights.len);
    defer allocator.free(target_indicator_lights);

    for (joltage_counter.lights, 0..) |j, i| {
        target_indicator_lights[i] = (j % 2 == 1);
    }

    const button_combo_cache_key = IndicatorLights.init(target_indicator_lights, 0).hash();
    if (button_combo_cache.get(button_combo_cache_key)) |combos| {
        for (combos.items) |combo| {
            var joltages = try allocator.alloc(isize, joltage_counter.lights.len);
            defer allocator.free(joltages);
            for (joltage_counter.lights, 0..) |light, i| {
                joltages[i] = @intCast(light);
            }

            var valid = true;
            outer: for (combo) |button_index| {
                for (machine.button_schematics[button_index].schematic) |joltage_index| {
                    joltages[joltage_index] -= 1;
                    if (joltages[joltage_index] < 0) {
                        valid = false;
                        break :outer;
                    }
                }
            }
            if (!valid) continue;

            var halved_joltages = try allocator.alloc(usize, joltages.len);
            defer allocator.free(halved_joltages);
            for (joltages, 0..) |joltage, i| {
                halved_joltages[i] = @intCast(@divExact(joltage, 2));
            }

            const recursive_min_presses = try recursive(allocator, machine, JoltageCounter.init(halved_joltages), button_combo_cache, joltage_cache);
            if (recursive_min_presses < std.math.maxInt(usize)) {
                min_presses = @min(min_presses, combo.len + 2 * recursive_min_presses);
            }
        }
    }

    try joltage_cache.put(joltage_cache_key, min_presses);

    return min_presses;
}

fn generateButtonCombinations(
    allocator: std.mem.Allocator,
    machine: Machine,
    current_combo: *std.ArrayList(usize),
    start_button: usize,
    button_combo_cache: *std.AutoHashMap(u64, std.ArrayList([]usize)),
) !void {
    const num_lights = machine.joltage_counter.lights.len;

    var lights = try allocator.alloc(bool, num_lights);
    defer allocator.free(lights);
    @memset(lights, false);

    for (0..num_lights) |light_index| {
        var count: usize = 0;
        for (current_combo.items) |button_index| {
            for (machine.button_schematics[button_index].schematic) |affected_light| {
                if (affected_light == light_index) {
                    count += 1;
                    break;
                }
            }
        }
        lights[light_index] = (count % 2 == 1);
    }

    const button_combo_cache_key = IndicatorLights.init(lights, 0).hash();

    const button_combo = try allocator.alloc(usize, current_combo.items.len);
    @memcpy(button_combo, current_combo.items);

    const entry = try button_combo_cache.getOrPut(button_combo_cache_key);
    if (!entry.found_existing) {
        entry.value_ptr.* = try std.ArrayList([]usize).initCapacity(allocator, 1);
    }
    try entry.value_ptr.append(allocator, button_combo);

    const num_buttons = machine.button_schematics.len;
    for (start_button..num_buttons) |button_index| {
        try current_combo.append(allocator, button_index);
        try generateButtonCombinations(allocator, machine, current_combo, button_index + 1, button_combo_cache);
        _ = current_combo.pop();
    }
}

fn solvePart2(allocator: std.mem.Allocator, machine: Machine) !usize {
    var button_combo_cache = std.AutoHashMap(u64, std.ArrayList([]usize)).init(allocator);
    defer {
        var it = button_combo_cache.valueIterator();
        while (it.next()) |combos| {
            for (combos.items) |combo| {
                allocator.free(combo);
            }
            combos.deinit(allocator);
        }
        button_combo_cache.deinit();
    }

    var current_combo = try std.ArrayList(usize).initCapacity(allocator, machine.button_schematics.len);
    defer current_combo.deinit(allocator);

    try generateButtonCombinations(allocator, machine, &current_combo, 0, &button_combo_cache);

    var joltage_cache = std.AutoHashMap(u64, usize).init(allocator);
    defer joltage_cache.deinit();

    return recursive(allocator, machine, machine.joltage_counter, &button_combo_cache, &joltage_cache);
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
            allocator.free(machine.joltage_counter.lights);
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
        total_presses += try solvePart1(allocator, machine);
    }

    std.debug.print("Total presses to configure indicator lights: {}\n", .{total_presses});

    total_presses = 0;
    for (machines.items) |machine| {
        total_presses += try solvePart2(allocator, machine);
    }

    std.debug.print("Total presses to reach joltage requirements: {}\n", .{total_presses});
}
