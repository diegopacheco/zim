const std = @import("std");
const io = std.io;
const fs = std.fs;
const os = std.os;
const mem = std.mem;
const Allocator = std.mem.Allocator;

pub const Mode = enum {
    Normal,
    Insert,
    Command,
};

pub const Editor = struct {
    allocator: Allocator,
    lines: std.ArrayList([]u8),
    cursor_x: usize,
    cursor_y: usize,
    mode: Mode,
    width: usize,
    height: usize,
    command_buffer: std.ArrayList(u8),
    filename: ?[]const u8,
    status_message: []u8,
    stdin: std.fs.File.Reader,
    stdout: std.fs.File.Writer,
    term_orig: std.posix.termios,

    pub fn init(allocator: Allocator) Editor {
        var stdin_file = std.io.getStdIn();
        var stdout_file = std.io.getStdOut();

        // Save original terminal settings
        var orig: std.posix.termios = undefined;
        _ = std.posix.tcgetattr(stdin_file.handle, &orig) catch unreachable;

        return Editor{
            .allocator = allocator,
            .lines = std.ArrayList([]u8).init(allocator),
            .cursor_x = 0,
            .cursor_y = 0,
            .mode = .Normal,
            .width = 80,
            .height = 24,
            .command_buffer = std.ArrayList(u8).init(allocator),
            .filename = null,
            .status_message = allocator.alloc(u8, 80) catch unreachable,
            .stdin = stdin_file.reader(),
            .stdout = stdout_file.writer(),
            .term_orig = orig,
        };
    }

    pub fn deinit(self: *Editor) void {
        // Restore terminal settings
        std.posix.tcsetattr(std.io.getStdIn().handle, .FLUSH, self.term_orig) catch {};

        for (self.lines.items) |line| {
            self.allocator.free(line);
        }
        self.lines.deinit();
        self.command_buffer.deinit();
        self.allocator.free(self.status_message);
    }

    pub fn setup_ui(self: *Editor) !void {
        // Get terminal size if possible
        if (self.get_window_size()) |size| {
            self.width = size.width;
            self.height = size.height;
        }

        // Set terminal to raw mode
        var raw = self.term_orig;
        raw.lflag.ECHO = false;
        raw.lflag.ICANON = false;
        raw.lflag.ISIG = false;
        raw.lflag.IEXTEN = false;
        raw.iflag.IXON = false;
        raw.iflag.ICRNL = false;
        raw.iflag.BRKINT = false;
        raw.iflag.INPCK = false;
        raw.iflag.ISTRIP = false;
        raw.oflag.OPOST = false;
        raw.cflag.CSIZE = .CS8;
        raw.cc[@intFromEnum(std.posix.V.MIN)] = 1;
        raw.cc[@intFromEnum(std.posix.V.TIME)] = 0;
        try std.posix.tcsetattr(std.io.getStdIn().handle, .FLUSH, raw);

        // Add a blank line to start with
        try self.lines.append(try self.allocator.alloc(u8, 0));

        // Set initial status message
        @memcpy(self.status_message[0..78], "HELP: ESC = normal mode, i = insert mode, :q = quit, :w = save              ");

        // Initial render
        try self.render();
    }

    fn get_window_size(self: *Editor) ?struct { width: usize, height: usize } {
        _ = self;
        var winsize: std.posix.winsize = undefined;
        const result = std.posix.system.ioctl(1, std.posix.T.IOCGWINSZ, @intFromPtr(&winsize));
        if (result == 0) {
            return .{ .width = winsize.ws_col, .height = winsize.ws_row };
        }
        return null;
    }

    pub fn get_input(self: *Editor) ![]const u8 {
        var buf: [3]u8 = undefined;
        const bytes_read = try self.stdin.read(&buf);

        if (bytes_read == 0) return "exit";

        // If it's ESC
        if (buf[0] == 27) {
            return "escape";
        }

        return self.allocator.dupe(u8, buf[0..bytes_read]);
    }

    pub fn process_input(self: *Editor, input: []const u8) !void {
        defer self.allocator.free(input);

        switch (self.mode) {
            .Normal => try self.process_normal_mode(input),
            .Insert => try self.process_insert_mode(input),
            .Command => try self.process_command_mode(input),
        }

        try self.render();
    }

    fn process_normal_mode(self: *Editor, input: []const u8) !void {
        if (input.len == 0) return;

        switch (input[0]) {
            'i' => {
                self.mode = .Insert;
                @memcpy(self.status_message[0..12], "-- INSERT --");
            },
            ':' => {
                self.mode = .Command;
                self.command_buffer.clearRetainingCapacity();
                @memcpy(self.status_message[0..1], ":");
            },
            'h' => {
                if (self.cursor_x > 0) {
                    self.cursor_x -= 1;
                }
            },
            'j' => {
                if (self.cursor_y < self.lines.items.len - 1) {
                    self.cursor_y += 1;
                    self.cursor_x = @min(self.cursor_x, self.lines.items[self.cursor_y].len);
                }
            },
            'k' => {
                if (self.cursor_y > 0) {
                    self.cursor_y -= 1;
                    self.cursor_x = @min(self.cursor_x, self.lines.items[self.cursor_y].len);
                }
            },
            'l' => {
                if (self.cursor_y < self.lines.items.len and self.cursor_x < self.lines.items[self.cursor_y].len) {
                    self.cursor_x += 1;
                }
            },
            else => {},
        }
    }

    fn process_insert_mode(self: *Editor, input: []const u8) !void {
        if (input.len == 0) return;

        if (std.mem.eql(u8, input, "escape")) {
            self.mode = .Normal;
            @memcpy(self.status_message[0..12], "-- NORMAL --");
            return;
        }

        if (self.lines.items.len == 0) {
            try self.lines.append(try self.allocator.alloc(u8, 0));
        }

        switch (input[0]) {
            '\r', '\n' => {
                // Split the line at cursor
                const current_line = self.lines.items[self.cursor_y];
                const new_line = try self.allocator.alloc(u8, current_line.len - self.cursor_x);

                @memcpy(new_line, current_line[self.cursor_x..]);

                // Truncate current line
                const truncated = try self.allocator.alloc(u8, self.cursor_x);
                @memcpy(truncated, current_line[0..self.cursor_x]);

                self.allocator.free(current_line);
                self.lines.items[self.cursor_y] = truncated;

                // Insert new line
                try self.lines.insert(self.cursor_y + 1, new_line);
                self.cursor_y += 1;
                self.cursor_x = 0;
            },
            127, 8 => { // Backspace or Delete
                if (self.cursor_x > 0) {
                    var current_line = self.lines.items[self.cursor_y];
                    var new_line = try self.allocator.alloc(u8, current_line.len - 1);

                    @memcpy(new_line[0 .. self.cursor_x - 1], current_line[0 .. self.cursor_x - 1]);
                    @memcpy(new_line[self.cursor_x - 1 ..], current_line[self.cursor_x..]);

                    self.allocator.free(current_line);
                    self.lines.items[self.cursor_y] = new_line;
                    self.cursor_x -= 1;
                } else if (self.cursor_y > 0) {
                    // Join with previous line
                    const prev_line = self.lines.items[self.cursor_y - 1];
                    const current_line = self.lines.items[self.cursor_y];

                    var new_line = try self.allocator.alloc(u8, prev_line.len + current_line.len);
                    @memcpy(new_line[0..prev_line.len], prev_line);
                    @memcpy(new_line[prev_line.len..], current_line);

                    self.allocator.free(prev_line);
                    self.allocator.free(current_line);

                    self.lines.items[self.cursor_y - 1] = new_line;
                    _ = self.lines.orderedRemove(self.cursor_y);

                    self.cursor_y -= 1;
                    self.cursor_x = prev_line.len;
                }
            },
            else => {
                var current_line = self.lines.items[self.cursor_y];
                var new_line = try self.allocator.alloc(u8, current_line.len + 1);

                @memcpy(new_line[0..self.cursor_x], current_line[0..self.cursor_x]);
                new_line[self.cursor_x] = input[0];
                @memcpy(new_line[self.cursor_x + 1 ..], current_line[self.cursor_x..]);

                self.allocator.free(current_line);
                self.lines.items[self.cursor_y] = new_line;
                self.cursor_x += 1;
            },
        }
    }

    fn process_command_mode(self: *Editor, input: []const u8) !void {
        if (input.len == 0) return;

        if (std.mem.eql(u8, input, "escape")) {
            self.mode = .Normal;
            @memcpy(self.status_message[0..12], "-- NORMAL --");
            return;
        }

        switch (input[0]) {
            '\r', '\n' => {
                // Execute command
                const cmd = try self.command_buffer.toOwnedSlice();
                defer self.allocator.free(cmd);

                if (cmd.len > 0) {
                    if (std.mem.eql(u8, cmd, "q")) {
                        // Quit without saving
                        std.process.exit(0);
                    } else if (std.mem.eql(u8, cmd, "w")) {
                        // Save file
                        if (self.filename) |fname| {
                            try self.save_file(fname);
                            @memcpy(self.status_message[0..10], "File saved");
                        } else {
                            @memcpy(self.status_message[0..21], "No filename specified");
                        }
                    } else if (std.mem.startsWith(u8, cmd, "w ")) {
                        // Save file with name
                        const fname = cmd[2..];
                        self.filename = try self.allocator.dupe(u8, fname);
                        try self.save_file(fname);
                        @memcpy(self.status_message[0..10], "File saved");
                    } else if (std.mem.eql(u8, cmd, "i")) {
                        self.mode = .Insert;
                        @memcpy(self.status_message[0..12], "-- INSERT --");
                        return;
                    } else {
                        @memcpy(self.status_message[0..15], "Unknown command");
                    }
                }

                self.mode = .Normal;
            },
            127, 8 => { // Backspace or Delete
                if (self.command_buffer.items.len > 0) {
                    _ = self.command_buffer.pop();
                }
            },
            else => {
                try self.command_buffer.append(input[0]);
            },
        }
    }

    fn save_file(self: *Editor, path: []const u8) !void {
        const file = try fs.cwd().createFile(path, .{});
        defer file.close();

        const writer = file.writer();

        for (self.lines.items, 0..) |line, i| {
            try writer.writeAll(line);
            if (i < self.lines.items.len - 1) {
                try writer.writeByte('\n');
            }
        }
    }

    fn render(self: *Editor) !void {
        // Clear screen
        try self.stdout.writeAll("\x1b[2J");
        try self.stdout.writeAll("\x1b[H");

        // Draw lines (leave space for status at bottom)
        const max_lines = if (self.height > 2) self.height - 2 else 1;

        for (self.lines.items, 0..) |line, line_num| {
            if (line_num >= max_lines) break;

            // Line number
            try self.stdout.print("{d:>4} ", .{line_num + 1});

            // Content
            if (line.len > 0) {
                try self.stdout.writeAll(line);
            }

            try self.stdout.writeAll("\r\n");
        }

        // Fill remaining lines if needed
        for (self.lines.items.len..max_lines) |line_num| {
            try self.stdout.print("{d:>4} \r\n", .{line_num + 1});
        }

        // Status line
        try self.stdout.writeAll("\x1b[7m"); // Inverse video

        var status = try self.allocator.alloc(u8, self.width);
        defer self.allocator.free(status);
        @memset(status, ' ');

        // Mode and filename
        const mode_str: []const u8 = switch (self.mode) {
            .Normal => "NORMAL",
            .Insert => "INSERT",
            .Command => "COMMAND",
        };

        var status_text = if (self.filename) |f|
            try std.fmt.allocPrint(self.allocator, "{s} - {s}", .{ mode_str, f })
        else
            try std.fmt.allocPrint(self.allocator, "{s} - [No Name]", .{mode_str});
        defer self.allocator.free(status_text);

        const len = @min(status_text.len, status.len);
        @memcpy(status[0..len], status_text[0..len]);

        // Cursor position
        const pos_str = try std.fmt.allocPrint(self.allocator, "{d}:{d}", .{ self.cursor_y + 1, self.cursor_x + 1 });
        defer self.allocator.free(pos_str);

        if (pos_str.len <= status.len) {
            @memcpy(status[status.len - pos_str.len ..], pos_str);
        }

        try self.stdout.writeAll(status);
        try self.stdout.writeAll("\x1b[0m\r\n"); // Reset formatting

        // Command or message
        if (self.mode == .Command) {
            try self.stdout.writeAll(":");
            try self.stdout.writeAll(self.command_buffer.items);
        } else {
            try self.stdout.writeAll(self.status_message);
        }

        // Position cursor
        if (self.mode == .Command) {
            try self.stdout.print("\x1b[{d};{d}H", .{ self.height, self.command_buffer.items.len + 2 });
        } else {
            try self.stdout.print("\x1b[{d};{d}H", .{ self.cursor_y + 1, self.cursor_x + 6 }); // +6 for line numbers and space
        }
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var editor = Editor.init(allocator);
    defer editor.deinit();

    try editor.setup_ui();

    while (true) {
        const input = try editor.get_input();

        if (std.mem.eql(u8, input, "exit")) {
            break;
        }

        try editor.process_input(input);
    }
}
