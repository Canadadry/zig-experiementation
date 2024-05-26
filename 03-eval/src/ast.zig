const std = @import("std");
const token = @import("token.zig");

pub const NodeType = enum {
	value,
	infix,
	prefix,
};

pub fn allocate(alloc:std.mem.Allocator,n:Node) !*Node{
		const node = try alloc.alloc(Node, 1);
		node[0] = n;
		return &node[0];
}

pub const Node = union(NodeType) {
	value: f64,
	infix: Infix,
	prefix: Prefix,

    pub fn eval(self: Node) f64 {
        switch (self) {
            .value => |v| return v,
            .infix => |i| return i.eval(),
            .prefix => |p| return p.eval(),
        }
    }

    pub fn free(self: *Node,alloc:std.mem.Allocator) void {
        switch (self.*) {
            .infix => |i| {
           		i.left.free(alloc);
            	i.right.free(alloc);
            },
            .prefix => |p| {
           		p.value.free(alloc);
            },
            else => {},
        }
        alloc.free(self[0..0]);
    }
};

pub const Infix = struct{
	left:*Node,
	right:*Node,
	op:*const fn (l:f64,r:f64)f64,

	pub fn eval(self: Infix) f64 {
		return self.op(self.left.eval(), self.right.eval());
	}
};

pub const Prefix = struct{
	value:*Node,
	op:*const fn (v:f64)f64,

	pub fn eval(self: Prefix) f64 {
		return self.op(self.value.eval());
	}
};

pub fn getInfixFn(t: token.TokenType) ?*const fn (f64,f64) f64 {
    return switch (t) {
    	.plus => Add,
    	.minus => Sub,
    	.star => Mul,
    	.slash => Div,
    	.percent => Mod,
        .double_star => Pow,
        .double_slash => IntDiv,
        else => null,
    };
}

pub fn getPrefixFn(t: token.TokenType) ?*const fn (f64) f64 {
    return switch (t) {
    	.minus => Neg,
        else => null,
    };
}

pub fn Add(l: f64, r: f64) f64 { return l + r; }
pub fn Sub(l: f64, r: f64) f64 { return l - r; }
pub fn Mul(l: f64, r: f64) f64 { return l * r; }
pub fn Div(l: f64, r: f64) f64 { return l / r; }
pub fn Mod(l: f64, r: f64) f64 { return @mod(l,r); }
pub fn Pow(l: f64, r: f64) f64 { return l / r; }
pub fn IntDiv(l: f64, r: f64) f64 { return @floor(l / r); }
pub fn Neg(v: f64) f64 { return -v; }

test "Node Evaluation" {
	const allocator = std.testing.allocator;

    const tests = [_]struct {
    	expected: f64,
    	tree: *Node,
    }{
        .{
        	.expected =  1.0 ,
        	.tree = try allocate(allocator,Node{ .value = 1.0, })
         },
        .{
        	.expected = -1.0 ,
        	.tree = try allocate(allocator,Node{
         		.prefix = Prefix{
           			.value = try allocate(allocator,Node{ .value = 1.0 }),
              		.op = Neg
                }
            })
        },
        .{
        	.expected =  3.0 ,
        	.tree = try allocate(allocator,Node{
         		.infix = Infix{
           			.left = try allocate(allocator,Node{ .value = 1.0 }),
              		.right = try allocate(allocator,Node{ .value = 2.0 }),
                	.op = Add
                 }
            })
        },
        .{
        	.expected =  0.0 ,
        	.tree = try allocate(allocator,Node{
         		.infix = Infix{
           			.left = try allocate(allocator,Node{ .value = 1.0 }),
              		.right = try allocate(allocator,Node{ .value = 1.0 }),
                	.op = Sub
                 }
            })
        },
        .{
        	.expected = -2.0 ,
        	.tree = try allocate(allocator,Node{
         		.infix = Infix{
           			.left = try allocate(allocator,Node{
              			.prefix = Prefix{
                 			.value = try allocate(allocator,Node{ .value = 1.0 }),
                  			.op = Neg
                    	}
                     }),
                    .right = try allocate(allocator,Node{ .value = 2.0 }),
                    .op = Mul
                 }
            })
        },
    };

    for (tests,0..) |tt, index| {
        const result = tt.tree.eval();
        tt.tree.free(allocator);
        if (result != tt.expected) {
            std.testing.expectEqual(tt.expected, result) catch |err| {
                std.debug.print("failed at index {d}: expected {}, but got {}", .{ index, tt.expected, result });
                return err;
            };
        }
    }
}
