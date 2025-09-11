const time = rp2xxx.time;
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const usb_if = @import("usb_if.zig");
const usb_dev = rp2xxx.usb.Usb(.{});

var data: [7]u8 = [7]u8{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
var current_pointer: usize = 1;
const HidAction = union(enum) {
    press: u8,
    release,
};
pub const HelperSettings = struct {
    max_buffer_size: usize,
};
pub fn HelperType(settings: HelperSettings) type {
    const QueueHidCodes = GenericQueue(u8, settings.max_buffer_size);
    return struct {
        const Self = @This();
        var queue_hid: QueueHidCodes = QueueHidCodes.Create();
        var last_hid_send: u64 = 0;
        var buf: [settings.max_buffer_size]u8 = undefined;
        const send_rate_us: u64 = 12000; // some number a little slower than 10ms
        pub fn Create() Self {
            usb_if.init(usb_dev);
            return Self{};
        }
        pub fn get_queue_size(_: Self) usize {
            return queue_hid.Count();
        }
        pub fn do_house_keeping(_: Self) !void {
            usb_dev.task(false) catch unreachable; // Process pending USB housekeeping
            const current_time = time.get_time_since_boot().to_us();
            if (current_time > last_hid_send + send_rate_us) {
                try flush_next();
                last_hid_send = current_time;
            }
        }
        fn flush_next() !void {
            data[2] = queue_hid.dequeue() catch 0;
            data[3] = queue_hid.dequeue() catch 0;
            data[4] = queue_hid.dequeue() catch 0;
            data[5] = queue_hid.dequeue() catch 0;
            data[6] = queue_hid.dequeue() catch 0;

            usb_if.send_keyboard_report(usb_dev, &data);
        }
        pub fn send_string(_: Self, comptime fmt: []const u8, args: anytype) !void {
            const msg = try std.fmt.bufPrint(&buf, fmt, args);
            for (msg) |char| {
                queue_hid.enqueue(char_to_hid(char)) catch {};
            }
        }
    };
}
const std = @import("std");

// todo:
//  setup a bread board with a hall sensor on it
//  measure the sensors input
//  add an rgb
//
//

pub fn char_to_hid(char: u8) u8 {
    const hid_val: u8 = switch (char) {
        'a' => KC_A,
        'b' => KC_B,
        'c' => KC_C,
        'd' => KC_D,
        'e' => KC_E,
        'f' => KC_F,
        'g' => KC_G,
        'h' => KC_H,
        'i' => KC_I,
        'j' => KC_J,
        'k' => KC_K,
        'l' => KC_L,
        'm' => KC_M,
        'n' => KC_N,
        'o' => KC_O,
        'p' => KC_P,
        'q' => KC_Q,
        'r' => KC_R,
        's' => KC_S,
        't' => KC_T,
        'u' => KC_U,
        'v' => KC_V,
        'w' => KC_W,
        'x' => KC_X,
        'y' => KC_Y,
        'z' => KC_Z,
        'A' => KC_A,
        'B' => KC_B,
        'C' => KC_C,
        'D' => KC_D,
        'E' => KC_E,
        'F' => KC_F,
        'G' => KC_G,
        'H' => KC_H,
        'I' => KC_I,
        'J' => KC_J,
        'K' => KC_K,
        'L' => KC_L,
        'M' => KC_M,
        'N' => KC_N,
        'O' => KC_O,
        'P' => KC_P,
        'Q' => KC_Q,
        'R' => KC_R,
        'S' => KC_S,
        'T' => KC_T,
        'U' => KC_U,
        'V' => KC_V,
        'W' => KC_W,
        'X' => KC_X,
        'Y' => KC_Y,
        'Z' => KC_Z,
        '1' => KC_1,
        '2' => KC_2,
        '3' => KC_3,
        '4' => KC_4,
        '5' => KC_5,
        '6' => KC_6,
        '7' => KC_7,
        '8' => KC_8,
        '9' => KC_9,
        '0' => KC_0,
        ' ' => KC_SPACE,
        '.' => KC_DOT,
        '\n' => KC_ENTER,
        else => KC_DOT,
    };

    return hid_val;
}

pub const KC_BOOT = 0x0000;
pub const KC_A = 0x0004;
pub const KC_B = 0x0005;
pub const KC_C = 0x0006;
pub const KC_D = 0x0007;
pub const KC_E = 0x0008;
pub const KC_F = 0x0009;
pub const KC_G = 0x000A;
pub const KC_H = 0x000B;
pub const KC_I = 0x000C;
pub const KC_J = 0x000D;
pub const KC_K = 0x000E;
pub const KC_L = 0x000F;
pub const KC_M = 0x0010;
pub const KC_N = 0x0011;
pub const KC_O = 0x0012;
pub const KC_P = 0x0013;
pub const KC_Q = 0x0014;
pub const KC_R = 0x0015;
pub const KC_S = 0x0016;
pub const KC_T = 0x0017;
pub const KC_U = 0x0018;
pub const KC_V = 0x0019;
pub const KC_W = 0x001A;
pub const KC_X = 0x001B;
pub const KC_Y = 0x001C;
pub const KC_Z = 0x001D;
pub const KC_1 = 0x001E;
pub const KC_2 = 0x001F;
pub const KC_3 = 0x0020;
pub const KC_4 = 0x0021;
pub const KC_5 = 0x0022;
pub const KC_6 = 0x0023;
pub const KC_7 = 0x0024;
pub const KC_8 = 0x0025;
pub const KC_9 = 0x0026;
pub const KC_0 = 0x0027;
pub const KC_ENTER = 0x0028;
pub const KC_SPACE = 0x002C;
pub const KC_DOT = 0x0037;
pub const KC_BACKSLASH = 0x0031;

const EnqueueError = error{CapacityExceeded};
pub const DequeueError = error{NoElements};
pub fn GenericQueue(comptime T: type, comptime max_capacity: usize) type {
    return struct {
        const Self = @This();
        data: [max_capacity]T,
        size: usize = 0,
        pub fn Create() Self {
            return Self{ .data = [1]T{undefined} ** max_capacity };
        }
        pub fn Count(self: *Self) usize {
            return self.size;
        }
        pub fn enqueue(self: *Self, element: T) EnqueueError!void {
            if (self.size == max_capacity) {
                return EnqueueError.CapacityExceeded;
            }
            self.data[self.size] = element;
            self.size += 1;
        }
        pub fn dequeue_count(self: *Self, count: u8) DequeueError!void {
            var i = count;
            while (i > 0) {
                _ = try dequeue(self);
                i -= 1;
            }
        }
        pub fn dequeue(self: *Self) DequeueError!T {
            if (self.size == 0) {
                return DequeueError.NoElements;
            }
            const head_element = self.data[0];

            // todo: don't do this shifting of all values. Use a better queue implementation instead
            for (self.data[1..self.size], 0..self.size - 1) |item, index| {
                self.data[index] = item;
            }
            self.size = self.size - 1;
            return head_element;
        }

        pub fn peek_all(self: *Self) []T {
            return self.data[0..self.size];
        }
        pub fn peek(self: *Self) ?T {
            if (self.size > 0) {
                return self.data[0];
            } else {
                return null;
            }
        }
    };
}
