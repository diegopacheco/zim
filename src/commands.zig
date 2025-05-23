const std = @import("std");
const Editor = @import("editor.zig").Editor;

pub fn execute_command(editor: *Editor, command: []const u8) !void {
    switch (command) {
        ":w" => try save_file(editor),
        ":q" => try quit_editor(editor),
        ":wq" => {
            try save_file(editor);
            try quit_editor(editor);
        },
        else => return error.UnknownCommand,
    }
}

fn save_file(editor: *Editor) !void {
    // Implementation for saving the file
    const file_path = editor.file_path;
    const buffer = editor.buffer;
    try std.utils.file_io.write_file(file_path, buffer);
}

fn quit_editor(editor: *Editor) !void {
    // Implementation for quitting the editor
    // Clean up resources if necessary
    std.debug.print("Exiting editor...\n", .{});
    // Exit logic here
}

const error = error{
    UnknownCommand,
};