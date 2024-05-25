const std = @import("std");

const NodeType = enum {
	value,
	infix,
	prefix,
};

const Node = union(NodeType) {
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
};

const Infix = struct{
	left:*const Node,
	right:*const Node,
	op:*const fn (l:f64,r:f64)f64,

	pub fn eval(self: Infix) f64 {
		return self.op(self.left.eval(), self.right.eval());
	}
};

const Prefix = struct{
	val:*const Node,
	op:*const fn (v:f64)f64,

	pub fn eval(self: Prefix) f64 {
		return self.op(self.val.eval());
	}
};

fn Add(l: f64, r: f64) f64 { return l + r; }
fn Sub(l: f64, r: f64) f64 { return l - r; }
fn Mul(l: f64, r: f64) f64 { return l * r; }
fn Div(l: f64, r: f64) f64 { return l / r; }
fn Mod(l: f64, r: f64) f64 { return @mod(l,r); }
fn Pow(l: f64, r: f64) f64 { return l / r; }
fn IntDiv(l: f64, r: f64) f64 { return @floor(l / r); }
fn Neg(v: f64) f64 { return -v; }

test "Node Evaluation" {
    const tests = [_]struct {
    	expected: f64,
    	tree: Node,
    }{
        .{ .expected =  1.0 , .tree = Node{ .value = 1.0, }},
        .{ .expected = -1.0 , .tree = Node{ .prefix = Prefix{ .val = &Node{ .value = 1.0 }, .op = Neg } }},
        .{ .expected =  3.0 , .tree = Node{ .infix = Infix{ .left = &Node{ .value = 1.0 }, .right = &Node{ .value = 2.0 }, .op = Add } }},
        .{ .expected =  0.0 , .tree = Node{ .infix = Infix{ .left = &Node{ .value = 1.0 }, .right = &Node{ .value = 1.0 }, .op = Sub } }},
        .{ .expected =  1.0 , .tree = Node{ .infix = Infix{ .left = &Node{ .value = 1.0 }, .right = &Node{ .value = 1.0 }, .op = Mul } }},
        .{ .expected =  1.0 , .tree = Node{ .infix = Infix{ .left = &Node{ .value = 1.0 }, .right = &Node{ .value = 1.0 }, .op = Div } }},
        .{ .expected =  1.5 , .tree = Node{ .infix = Infix{ .left = &Node{ .value = 3.0 }, .right = &Node{ .value = 2.0 }, .op = Div } }},
        .{ .expected = -2.0 , .tree = Node{ .infix = Infix{ .left = &Node{ .prefix = Prefix{ .val = &Node{ .value = 1.0 }, .op = Neg } }, .right = &Node{ .value = 2.0 }, .op = Mul } }},
    };

    for (tests,0..) |tt, index| {
        const result = tt.tree.eval();
        if (result != tt.expected) {
            std.testing.expectEqual(tt.expected, result) catch |err| {
                std.debug.print("failed at index {d}: expected {}, but got {}", .{ index, tt.expected, result });
                return err;
            };
        }
    }
}
