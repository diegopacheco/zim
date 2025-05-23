const std = @import("std");
const Editor = @import("editor").Editor;

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
