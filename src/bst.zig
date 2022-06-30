const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os;

pub fn BinarySearchTree(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: *mem.Allocator,
        root: ?*Node = null,

        const Node = struct {
            left: ?*Node = null,
            right: ?*Node = null,
            value: T,
        };

        pub fn init(allocator: *mem.Allocator) Self {
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
        ) ?T {
            var node: *?*Node = &self.root;
            var parent_node: ?*?*Node = null;
            var direction: bool = false;
            var min: ?T = null;
            while (node.*) |safe_node| {
                if (safe_node.value == value) {
                    min = findMinRight(self.allocator, safe_node);
                    // there was a min in the right sub tree
                    if (min) |safe_min| {
                        // the node with the value was killed
                        // so just assign
                        safe_node.value = value;
                    // there wasn't a right sub tree at all
                    } else {
                        // so kill the target node
                        // then link target's parent to target's left child
                        // but to link to the parent i need to know if the
                        // target was the left or right child of its parent
                        // otherwise i run the risk of lopping off a sub tree
                        // leaking memory on delete
                        self.allocator.destroy(safe_node);
                        // target was left child
                        // null problems fun...
                        if (direction) {
                            parent_node.left = safe_node.left;
                        // target was right child
                        } else {
                            parent_node.right = safe_node.right;
                        }
                    }
                    safe_node.value = min;
                    break;
                }
                parent_node = node;

                // inlined traversal function so i can record what side tranversal went down
                var next: *?*Node = undefined;
                if (safe_node.value > value) {
                    next = &safe_node.left;
                    direction = true;
                } else {
                    next = &safe_node.right;
                    direction = false;
                }
                node = next;
            }
            return min;
        }

        fn findMinRight(
            allocator: *mem.Allocator,
            node: *Node,
        ) T {
            var min: *?*Node = &node.right;
            var value: ?T = null;
            while (min.*) |safe_min| {
                if (safe_min.left) |safe_left| {
                    min = &safe_left;
                }
            }
            if (min.*) |safe_min| {
                value = min.*.?.*.value;
                // should be deleting a leaf
                allocator.destroy(min.*);
            }
            return value;
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

        pub fn printInorder(self: *Self) os.WriteError!void {
            const stdout = io.getStdOut().writer();
            try printInorderRecur(self.root, &stdout);
        }

        fn printInorderRecur(
            node: ?*Node,
            stdout: *const io.Writer(fs.File, os.WriteError, fs.File.write)
        ) os.WriteError!void {
            if (node) |safe_node| {
                try printInorderRecur(safe_node.left, stdout);
                try stdout.print("value: {}\n", .{safe_node.value});
                try printInorderRecur(safe_node.right, stdout);
            }
        }

        pub fn deinit(self: *Self) void {
            deinitRecur(self.allocator, self.root);
        }

        fn deinitRecur(
            allocator: *mem.Allocator,
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
