const std = @import("std");

pub const UI = struct {
    // Function to render the text buffer to the terminal
    pub fn render(buffer: *Buffer) void {
        // Clear the terminal
        clearScreen();

        // Display each line in the buffer
        for (buffer.lines) |line, index| {
            std.debug.print("{d}: {s}\n", .{index + 1, line});
        }

        // Move the cursor to the current position
        moveCursor(buffer.cursorPosition);
    }

    // Function to clear the terminal screen
    fn clearScreen() void {
        std.debug.print("\x1b[2J\x1b[H", .{}); // ANSI escape codes to clear the screen and move cursor to home
    }

    // Function to move the cursor to a specific position
    fn moveCursor(position: usize) void {
        std.debug.print("\x1b[{d};0H", .{position + 1}); // Move cursor to the specified line
    }
};