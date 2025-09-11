const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const usb_keyboard = @import("usb_keyboard.zig");

pub fn main() !void {
    var keyboard = usb_keyboard.HelperType(.{ .max_buffer_size = 2000 }).Create();
    var tick_counter: u64 = 0;
    while (true) {
        tick_counter += 1;
        // the logic here is just to write the same string when the keyboards internal queue is empty but send_string
        if (keyboard.get_queue_size() == 0) {
            try keyboard.send_string("tick_counter has now reached {}", .{tick_counter});
        }
        try keyboard.do_house_keeping();
    }
}
