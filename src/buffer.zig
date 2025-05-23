const std = @import("std");

pub const Buffer = struct {
    lines: std.ArrayList([]const u8),
    cursor_position: usize,

    pub fn init(allocator: *std.mem.Allocator) Buffer {
        return Buffer{
            .lines = std.ArrayList([]const u8).init(allocator),
            .cursor_position = 0,
        };
    }

    pub fn deinit(self: *Buffer) void {
        self.lines.deinit();
    }

    pub fn add_line(self: *Buffer, line: []const u8) !void {
        try self.lines.append(line);
        self.cursor_position = self.lines.len - 1; // Move cursor to the last line
    }

    pub fn delete_line(self: *Buffer, index: usize) !void {
        if (index >= self.lines.len) {
            return error.IndexOutOfBounds;
        }
        try self.lines.removeAt(index);
        if (self.cursor_position >= self.lines.len) {
            self.cursor_position = self.lines.len > 0 ? self.lines.len - 1 : 0;
        }
    }

    pub fn get_line(self: *Buffer, index: usize) ![]const u8 {
        if (index >= self.lines.len) {
            return error.IndexOutOfBounds;
        }
        return self.lines.at(index);
    }

    pub fn get_cursor_line(self: *Buffer) ![]const u8 {
        return self.get_line(self.cursor_position);
    }

    pub fn move_cursor(self: *Buffer, offset: isize) void {
        const new_position = @intCast(isize, self.cursor_position) + offset;
        if (new_position >= 0 && @intCast(usize, new_position) < self.lines.len) {
            self.cursor_position = @intCast(usize, new_position);
        }
    }

    const error = error{
        IndexOutOfBounds,
    };
};