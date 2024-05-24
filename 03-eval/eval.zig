const std = @import("std");

const maxLiteralLen = 25;
const TokenType = enum{
    left_par,right_par,
    plus,star,slash,minus,
    double_star,double_slash,percent,
    number,
    illegal,
    eof,
};
const Token = struct{
    type: TokenType,
    literal: [maxLiteralLen]u8,
    pos: usize,

    fn init(typ: TokenType, lit: []const u8, pos: usize) !Token {
        var literal: [maxLiteralLen]u8 = undefined;
        const len = @min(lit.len, maxLiteralLen);
        @memcpy( literal[0..len], lit);
        if (len < maxLiteralLen) {
            @memset(literal[len..], 0);
        }
        return Token{
            .type = typ,
            .literal = literal,
            .pos = pos,
        };
    }
};

const Lexer = struct{
    pub fn init(_:[]const u8) Lexer{
        return .{};
    }
    pub fn getNextToken(_:*Lexer)?Token{
        return null;
    }
};

test "lexer get newt token" {
    const testedString = "()+* /-**//\n12.32%#";
    const expectedTokens = [_]Token{
        try Token.init(.left_par, "(",0),
        try Token.init(.right_par, ")",1),
        try Token.init(.plus, "+",2),
        try Token.init(.star, "*",3),
        try Token.init(.slash, "/",5),
        try Token.init(.minus, "-",6),
        try Token.init(.double_star, "**",7),
        try Token.init(.double_slash, "//",9),
        try Token.init(.number, "12.32",12),
        try Token.init(.percent, "%",17),
        try Token.init(.illegal, "#",18),
        try Token.init(.eof, "",19),
    };

    var lexer = Lexer.init(testedString);
    var i:usize = 0;
    while(lexer.getNextToken()) |tok|{
        if (
            tok.type !=  expectedTokens[i].type
            or !std.mem.eql(u8,&tok.literal,&expectedTokens[i].literal)
        ) {
            std.debug.print("failed at \"{d}\" Expected: \"{}\", but got: \"{}\"\n", .{ i,expectedTokens[i],tok });
            return error.TestFailure;
        }
        i=i+1;
    }
    if(i!=expectedTokens.len){
        std.debug.print("failed found \"{d}\" token want \"{d}\"\n", .{ i,expectedTokens.len });
        return error.TestFailure;
    }
}