const std = @import("std");

pub const CommandMode = struct {
    // Add necessary fields for the CommandMode
    editor: *Editor, // Reference to the editor instance

    pub fn init(editor: *Editor) CommandMode {
        return CommandMode{
            .editor = editor,
        };
    }

    pub fn process_command(self: *CommandMode, command: []const u8) !void {
        if (std.mem.eql(u8, command, ":w")) {
            try self.editor.save();
        } else if (std.mem.eql(u8, command, ":q")) {
            try self.editor.quit();
        } else {
            std.debug.print("Unknown command: {s}\n", .{command});
        }
    }
};