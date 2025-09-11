const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const usb_keyboard = @import("usb_keyboard.zig");

pub fn main() !void {
    var keyboard = usb_keyboard.HelperType(.{ .max_buffer_size = 2000 }).Create();
    var tick_counter: i64 = 0;
    var enter: bool = false;
    while (true) {
        tick_counter += 1;
        // the logic here is just to write the same string when the keyboards internal queue is empty but send_string
        if (keyboard.get_queue_size() == 0) {
            enter = true;

            try keyboard.send_string("tick counter has now reached {} and that is all there is to say about that ! !!! ! ", .{tick_counter});
        }

        // This should be called at every tick, even though there has not been logged anything to keep the usb connection alive.
        try keyboard.do_house_keeping();
    }
}
