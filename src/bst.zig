const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os;

pub fn BinarySearchTree(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: *const mem.Allocator,
        root: ?*Node = null,

        const Node = struct {
            left: ?*Node = null,
            right: ?*Node = null,
            value: T,
        };

        pub fn init(allocator: *const mem.Allocator) Self {
            return Self {
                .allocator = allocator,
            };
        }

        pub fn insert(
            self: *Self,
            value: T
        ) mem.Allocator.Error!?*const Node {
            var node: *?*Node = &self.root;
            while (node.*) |safe_node| {
                node = traverse(safe_node, value);
            }
            node.* = try self.allocator.create(Node);
            node.*.?.* = .{
                .value = value,
            };
            return node.*;
        }

        pub fn search(
            self: *Self,
            value: T
        ) ?*const Node {
            var node: *?*Node = &self.root;
            var result: ?*const Node = null;
            while (node.*) |safe_node| {
                if (safe_node.value == value) {
                    result = safe_node;
                    break;
                }
                node = traverse(safe_node, value);
            }
            return result;
        }

        pub fn delete(
            self: *Self,
            value: T,
        ) void {
            var curr: *?*Node = &self.root;
            var prev: ?*Node = null;

            while (curr.*) |safe_curr| {
                if (safe_curr.value == value) {
                    break;
                }
                prev = safe_curr;
                curr = traverse(safe_curr, value);
            }

            if (curr.*) |safe_curr| {
                if (safe_curr.left == null or safe_curr.right == null) {
                    var new_curr: ?*Node = undefined;

                    if (safe_curr.left) |safe_curr_left| {
                        new_curr = safe_curr_left;
                    } else {
                        new_curr = safe_curr.right;
                    }

                    if (prev) |safe_prev| {
                        if (safe_curr == safe_prev.left) {
                            safe_prev.left = new_curr;
                        } else {
                            safe_prev.right = new_curr;
                        }
                    }

                    self.allocator.destroy(safe_curr);
                } else {
                    var successor: ?*Node = safe_curr.right;
                    var successor_parent: ?*Node = null;
                    while (successor.?.left) |safe_successor_left| {
                        const mut_safe_successor_left: ?*Node = safe_successor_left;
                        successor_parent = successor;
                        successor = mut_safe_successor_left;
                    }

                    if (successor_parent) |safe_successor_parent| {
                        safe_successor_parent.left = successor.?.right;
                    } else {
                        safe_curr.right = successor.?.right;
                    }

                    safe_curr.value = successor.?.value;
                    self.allocator.destroy(successor.?);
                }
            }
        }

        fn traverse(
            node: *Node,
            value: T
        ) *?*Node {
            var next: *?*Node = undefined;
            if (node.value > value) {
                next = &node.left;
            } else {
                next = &node.right;
            }
            return next;
        }

        pub fn printInorder(self: *Self) @TypeOf(io.getStdOut().writer()).Error!void {
            const writer = io.getStdOut().writer();
            try printInorderRecur(self.root, writer);
        }

        fn printInorderRecur(
            node: ?*Node,
            writer: fs.File.Writer
        ) fs.File.Writer.Error!void {
            if (node) |safe_node| {
                try printInorderRecur(safe_node.left, writer);
                try writer.print("value: {}\n", .{safe_node.value});
                try printInorderRecur(safe_node.right, writer);
            }
        }

        pub fn deinit(self: *Self) void {
            deinitRecur(self.allocator, self.root);
        }

        fn deinitRecur(
            allocator: *const mem.Allocator,
            node: ?*Node
        ) void {
            if (node) |safe_node| {
                deinitRecur(allocator, safe_node.left);
                deinitRecur(allocator, safe_node.right);
                allocator.destroy(safe_node);
            }
        }
    };
}
