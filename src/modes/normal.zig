const std = @import("std");

pub const NormalMode = struct {
    // Add fields to represent the state of the normal mode
    editor: *Editor,

    pub fn init(editor: *Editor) NormalMode {
        return NormalMode{ .editor = editor };
    }

    pub fn handle_input(self: *NormalMode, input: u8) !void {
        switch (input) {
            // Handle specific key inputs for normal mode
            'i' => {
                // Transition to insert mode
                try self.editor.set_mode(InsertMode.init(self.editor));
            },
            'q' => {
                // Quit the editor
                try self.editor.quit();
            },
            // Add more key bindings as needed
            else => {
                // Handle invalid input or other commands
                std.debug.print("Invalid command in normal mode: {c}\n", .{input});
            },
        }
    }
};