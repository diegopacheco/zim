const std = @import("std");

pub fn readFile(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{ .read = true });
    defer file.close();

    const allocator = std.heap.page_allocator;
    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    const bytes_read = try file.readAll(buffer);
    
    if (bytes_read != file_size) {
        return error.FileReadError;
    }
    
    return buffer;
}

pub fn writeFile(path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{ .write = true, .truncate = true });
    defer file.close();

    try file.writeAll(data);
}