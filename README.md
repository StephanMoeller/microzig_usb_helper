This helper makes it easy to log strings to the host by presenting the rp2040 as a keyboard.
Example of use: 

```c
const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const usb_keyboard = @import("usb_keyboard.zig");

pub fn main() !void {
    var keyboard = usb_keyboard.HelperType(.{ .max_buffer_size = 2000 }).Create();
    while (true) {
        // the logic here is just to write the same string when the keyboards internal queue is empty but send_string
        if (keyboard.get_queue_size() == 0) {
            try keyboard.send_string("SCANRATE: last {}, highest: {}, lowest: {}", .{ 10, 11, 12 });
        }
        try keyboard.do_house_keeping();
    }
}
```
