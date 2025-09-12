const time = rp2xxx.time;
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const usb_dev = rp2xxx.usb.Usb(.{});

const usb = rp2xxx.usb;
const hid = usb.hid;
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
        var last_released: bool = true;
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
            try queue_hid.fill_up_til_first_duplicate(&data);
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
        pub fn fill_up_til_first_duplicate(self: *Self, hid_buffer: []u8) !void {
            var i: usize = 2;
            while (i < hid_buffer.len) {
                if (self.Count() > 0) {
                    hid_buffer[i] = try self.dequeue();
                } else {
                    hid_buffer[i] = 0;
                }
                i += 1;
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

const usb_if = struct {
    pub const HID_KeymodifierCodes = enum(u8) {
        left_control = 0xe0,
        left_shift,
        left_alt,
        left_gui,
        right_control,
        right_shift,
        right_alt,
        right_gui,
    };

    // HID descriptor for keyboard
    const KeyboardReportDescriptor = hid.hid_usage_page(1, hid.UsageTable.desktop) ++
        hid.hid_usage(1, hid.DesktopUsage.keyboard) ++
        hid.hid_collection(hid.CollectionItem.Application) ++
        hid.hid_usage_page(1, hid.UsageTable.keyboard) ++
        hid.hid_usage_min(1, .{@intFromEnum(HID_KeymodifierCodes.left_control)}) ++
        hid.hid_usage_max(1, .{@intFromEnum(HID_KeymodifierCodes.right_gui)}) ++
        hid.hid_logical_min(1, "\x00".*) ++
        hid.hid_logical_max(1, "\x01".*) ++
        hid.hid_report_size(1, "\x01".*) ++
        hid.hid_report_count(1, "\x08".*) ++
        hid.hid_input(hid.HID_DATA | hid.HID_VARIABLE | hid.HID_ABSOLUTE) ++
        hid.hid_report_count(1, "\x06".*) ++
        hid.hid_report_size(1, "\x08".*) ++
        hid.hid_logical_max(1, "\x65".*) ++
        hid.hid_usage_min(1, "\x00".*) ++
        hid.hid_usage_max(1, "\x65".*) ++
        hid.hid_input(hid.HID_DATA | hid.HID_ARRAY | hid.HID_ABSOLUTE) ++
        hid.hid_collection_end();

    // HID report buffer
    const keyboardEpAddr = rp2xxx.usb.Endpoint.to_address(1, .In);

    const usb_packet_size = 7;
    const usb_config_len = usb.templates.config_descriptor_len + usb.templates.hid_in_descriptor_len;
    const usb_config_descriptor = usb.templates.config_descriptor(1, 1, 0, usb_config_len, 0x80, 500) ++
        (usb.types.InterfaceDescriptor{
            .interface_number = 1,
            .alternate_setting = 0,
            .num_endpoints = 1,
            .interface_class = 3,
            .interface_subclass = 0,
            .interface_protocol = 1,
            .interface_s = 4,
        }).serialize() ++
        (hid.HidDescriptor{
            .bcd_hid = 0x0111,
            .country_code = 0,
            .num_descriptors = 1,
            .report_length = KeyboardReportDescriptor.len,
        }).serialize() ++
        (usb.types.EndpointDescriptor{
            .endpoint_address = keyboardEpAddr,
            .attributes = @intFromEnum(usb.types.TransferType.Interrupt),
            .max_packet_size = usb_packet_size,
            .interval = 10,
        }).serialize();

    // Create keyboard HID driver
    var driver_keyboard = usb.hid.HidClassDriver{
        .ep_in = keyboardEpAddr,
        .report_descriptor = &KeyboardReportDescriptor,
    };

    // Register both drivers
    var drivers = [_]usb.types.UsbClassDriver{driver_keyboard.driver()};

    // This is our device configuration
    pub var DEVICE_CONFIGURATION: usb.DeviceConfiguration = .{
        .device_descriptor = &.{
            .descriptor_type = usb.DescType.Device,
            .bcd_usb = 0x0200,
            .device_class = 0,
            .device_subclass = 0,
            .device_protocol = 0,
            .max_packet_size0 = 64,
            .vendor = 0xFAFA,
            .product = 0x00F0,
            .bcd_device = 0x0100,
            // Those are indices to the descriptor strings (starting from 1)
            // Make sure to provide enough string descriptors!
            .manufacturer_s = 1,
            .product_s = 2,
            .serial_s = 3,
            .num_configurations = 1,
        },
        .config_descriptor = &usb_config_descriptor,
        .lang_descriptor = "\x04\x03\x09\x04", // length || string descriptor (0x03) || Engl (0x0409)
        .descriptor_strings = &.{
            &usb.utils.utf8_to_utf16_le("Stephan Møller"),
            &usb.utils.utf8_to_utf16_le("ZigMkay"),
            &usb.utils.utf8_to_utf16_le("00000001"),
            &usb.utils.utf8_to_utf16_le("Keyboard"),
        },
        .drivers = &drivers,
    };

    pub fn init(usb_dev_to_use: type) void {
        // First we initialize the USB clock
        usb_dev_to_use.init_clk();

        // Then initialize the USB device using the configuration defined above
        usb_dev_to_use.init_device(&DEVICE_CONFIGURATION) catch unreachable;

        // Initialize endpoint for HID device
        usb_dev_to_use.callbacks.endpoint_open(keyboardEpAddr, 512, usb.types.TransferType.Interrupt);
        std.log.debug("USB configured", .{});
    }

    pub fn send_keyboard_report(usb_dev_to_use: type, keycodes: *[7]u8) void {
        usb_dev_to_use.callbacks.usb_start_tx(keyboardEpAddr, keycodes);
    }
};

test "fill testing 1" {
    var buffer: [7]u8 = @splat(0);
    var queue = GenericQueue(u8, 1000).Create();
    try queue.fill_up_til_first_duplicate(&buffer);

    try std.testing.expectEqual(0, data[0]);
    try std.testing.expectEqual(0, data[1]);
    try std.testing.expectEqual(0, data[2]);
    try std.testing.expectEqual(0, data[3]);
    try std.testing.expectEqual(0, data[4]);
    try std.testing.expectEqual(0, data[5]);
    try std.testing.expectEqual(0, data[6]);
}

test "fill testing 2" {
    var buffer: [7]u8 = @splat(0);
    var queue = GenericQueue(u8, 1000).Create();

    try queue.enqueue(1);
    try queue.enqueue(2);
    try queue.enqueue(3);
    try queue.enqueue(4);
    try queue.enqueue(5);
    try queue.enqueue(6);
    try queue.enqueue(7);
    try queue.enqueue(8);

    try queue.fill_up_til_first_duplicate(&buffer);

    try std.testing.expectEqual(0, buffer[0]);
    try std.testing.expectEqual(0, buffer[1]);
    try std.testing.expectEqual(1, buffer[2]);
    try std.testing.expectEqual(2, buffer[3]);
    try std.testing.expectEqual(3, buffer[4]);
    try std.testing.expectEqual(4, buffer[5]);
    try std.testing.expectEqual(5, buffer[6]);

    try queue.fill_up_til_first_duplicate(&buffer);

    try std.testing.expectEqual(0, buffer[0]);
    try std.testing.expectEqual(0, buffer[1]);
    try std.testing.expectEqual(6, buffer[2]);
    try std.testing.expectEqual(7, buffer[3]);
    try std.testing.expectEqual(8, buffer[4]);
    try std.testing.expectEqual(0, buffer[5]);
    try std.testing.expectEqual(0, buffer[6]);

    try queue.fill_up_til_first_duplicate(&buffer);

    try std.testing.expectEqual(0, buffer[0]);
    try std.testing.expectEqual(0, buffer[1]);
    try std.testing.expectEqual(0, buffer[2]);
    try std.testing.expectEqual(0, buffer[3]);
    try std.testing.expectEqual(0, buffer[4]);
    try std.testing.expectEqual(0, buffer[5]);
    try std.testing.expectEqual(0, buffer[6]);
}
