const bst = @import("bst.zig");
const std = @import("std");

const heap = std.heap;
const io = std.io;
const mem = std.mem;
const os = std.os;

pub fn main() (mem.Allocator.Error || os.WriteError)!void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    var tree = bst.BinarySearchTree(isize).init(allocator);
    defer tree.deinit();

    _ = try tree.insert(12);
    _ = try tree.insert(4);
    _ = try tree.insert(15);
    _ = try tree.insert(13);
    _ = try tree.insert(15);
    _ = try tree.insert(16);
    _ = try tree.insert(17);

    const expected = 12;
    const actual = tree.search(expected);
    if (actual) |safe_actual| {
        const value = safe_actual.value;
        if (value == expected) {
            const stdout = io.getStdOut().writer();
            try stdout.print("The node has a value of {}.\n", .{value});
        }
    }

    const stdout = io.getStdOut().writer();

    try tree.printInorder();
    try stdout.print("\n", .{});
    _ = tree.delete(12);
    try tree.printInorder();
}
