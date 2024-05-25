const std = @import("std");
const token = @import("token.zig");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

const Precedence = enum {
    lowest,
    sum,
    product,
    prefix,
};

const ParseError = error {
	NoPrefixFunction,
	NoInfixFunction,
	InvalidNumberFormat,
	CannotAllocate,
	UnexpectedTokenFound,
};

fn getPrecedence(t: token.Token) Precedence {
    return switch (t.type) {
        .plus, .minus, .percent => Precedence.sum,
        .slash, .double_slash, .star, .double_star => Precedence.product,
        else => Precedence.lowest,
    };
}

fn getPrefixParseFn(t: token.Token) ?*const fn(*Parser) ParseError!*ast.Node {
    return switch (t.type) {
        .number => Parser.parseFloatLiteral,
        .minus => Parser.parsePrefixExpression,
        .left_par => Parser.parseGroupedExpression,
        else => null,
    };
}

fn getInfixParseFn(t: token.Token) ?*const fn(*Parser, *ast.Node) ParseError!*ast.Node {
    return switch (t.type) {
        .percent, .plus, .minus, .slash, .double_slash, .star, .double_star => Parser.parseInfixExpression,
        else => null,
    };
}

const Parser = struct {
    lexer: *lexer.Lexer,
    current: token.Token,
    next: token.Token,
    node:ast.Node,

    pub fn init(l: *lexer.Lexer) Parser {
        return Parser{
            .lexer = l,
            .current = l.getNextToken(),
            .next = l.getNextToken(),
            .node = ast.Node{.value=0.0},
        };
    }

    fn addNode(self:*Parser,n:ast.Node) ParseError!*ast.Node{
    	self.node = n;
     	if(self.current.type == .illegal){
      		return ParseError.CannotAllocate;
        }
     	return &self.node;
    }

    fn moveToNextToken(self: *Parser) void {
        self.current = self.next;
        self.next = self.lexer.getNextToken();
    }

    fn moveToNextTokenIfTypeIs(self: *Parser,t:token.TokenType) ParseError!void {
    	if(!self.isNextTokenA(t)){
     		return error.UnexpectedTokenFound;
       }
		self.moveToNextToken();
    }

    fn isCurrentTokenA(self: *Parser,t:token.TokenType) bool {
    	return self.current.type == t;
    }

    fn isNextTokenA(self: *Parser,t:token.TokenType) bool {
        return self.next.type == t;
    }

    fn getCurrentPrecedence(self: *Parser) Precedence {
    	return getPrecedence(self.current);
	}

	fn getNextPrecedence(self: *Parser) Precedence {
    	return getPrecedence(self.next);
	}

    pub fn parseExpression(self: *Parser, precedence: Precedence) ParseError!*ast.Node {
        const prefixFn = getPrefixParseFn(self.current) orelse return error.NoPrefixFunction;
        var leftExp = try prefixFn(self);
        while (@intFromEnum(precedence) < @intFromEnum(self.getNextPrecedence())) {
            const infixFn = getInfixParseFn(self.next) orelse return error.NoInfixFunction;
            self.moveToNextToken();
            leftExp = try infixFn(self, leftExp);
        }
        return leftExp;
    }

    fn parsePrefixExpression(self: *Parser) ParseError!*ast.Node {
        const op = ast.getPrefixFn(self.current.type) orelse return error.NoPrefixFunction;
        self.moveToNextToken();
        const value = try self.parseExpression(.prefix);
        return self.addNode(ast.Node{.prefix=ast.Prefix{ .value = value, .op = op }});
    }

    fn parseInfixExpression(self: *Parser, left: *ast.Node) ParseError!*ast.Node {
        const op = ast.getInfixFn(self.current.type) orelse return error.NoInfixFunction;
        const precedence = self.getCurrentPrecedence();
        self.moveToNextToken();
        const right = try self.parseExpression(precedence);
        return self.addNode(ast.Node{.infix=ast.Infix{ .left = left, .right = right, .op = op }});
    }

    pub fn parseGroupedExpression(self: *Parser) ParseError!*ast.Node {
        self.moveToNextToken();
        const exp = try self.parseExpression(.lowest);

        try self.moveToNextTokenIfTypeIs(.right_par);

        return exp;
    }

    pub fn parseFloatLiteral(self: *Parser) ParseError!*ast.Node {
        const value = std.fmt.parseFloat(f64, &self.current.literal) catch  {
            return error.InvalidNumberFormat;
        };
        return self.addNode(ast.Node{ .value = value });
    }

};


test "Node Evaluation" {
    const tests = [_]struct {
    	expected: f64,
    	expression: []const u8,
    }{
        .{ .expected =  1.0 , .expression = "1"},
        .{ .expected = -1.0 , .expression = "-1"},
        .{ .expected =  3.0 , .expression = "1+2"},
        .{ .expected =  0.0 , .expression = "1-1"},
        .{ .expected =  1.0 , .expression = "1*1"},
        .{ .expected =  1.0 , .expression = "1/1"},
        .{ .expected =  1.5 , .expression = "3/2"},
        .{ .expected = -2.0 , .expression = "-1*2"},
    };

    for (tests,0..) |tt, index| {
    	var l = lexer.Lexer.init(tt.expression);
        var parser = Parser.init(&l);
        const node = parser.parseExpression(.lowest) catch |err| {
            std.debug.print("failed at index {d}: return error {}", .{ index, err });
            return err;
        };
        const result = node.eval();
        if (result != tt.expected) {
            std.testing.expectEqual(tt.expected, result) catch |err| {
                std.debug.print("failed at index {d}: expected {}, but got {}", .{ index, tt.expected, result });
                return err;
            };
        }
    }
}
