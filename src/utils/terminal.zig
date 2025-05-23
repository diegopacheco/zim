const std = @import("std");

pub fn clearScreen() void {
    // ANSI escape code to clear the screen
    std.debug.print("\x1b[2J\x1b[H", .{});
}

pub fn moveCursor(x: u32, y: u32) void {
    // ANSI escape code to move the cursor to (x, y)
    std.debug.print("\x1b[{};{}H", .{y, x});
}

pub fn setCursorVisible(visible: bool) void {
    // ANSI escape code to set cursor visibility
    if (visible) {
        std.debug.print("\x1b[?25h", .{});
    } else {
        std.debug.print("\x1b[?25l", .{});
    }
}