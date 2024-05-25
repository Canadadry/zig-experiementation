const std = @import("std");

const maxLiteralLen = 25;

const TokenType = enum{
    left_par,right_par,
    plus,star,slash,minus,
    double_star,double_slash,percent,
    number,
    illegal,too_long_number,
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

const Bound = struct{
    start: usize,
    end: usize,
};

const Lexer = struct{
    source:  []const u8,
    current: usize,
    read:    usize,
    ch:      u8,

    pub fn init(source:[]const u8) Lexer{
        var l= Lexer{
            .source=source,
            .current=0,
            .read=0,
            .ch=0,
        };
        l.readChar();
        return l;
    }

    pub fn getNextToken(_:*Lexer)?Token{
        return null;
    }

    pub fn readChar(l:*Lexer)void {
        l.ch = l.peekChar();
        l.current = l.read;
        l.read=l.read+1;
    }

    pub fn peekChar(l:*Lexer) u8 {
        var ch:u8=0;
	    if(l.read < l.source.len){
            ch = l.source[l.read];
        }
        return ch;
    }

    fn readNumericBound(l:*Lexer) Bound {
        var bound = Bound{.start=l.current};
    	while(isNumeric(l.ch)){
    		l.readChar();
    	}
    	bound.end = l.current;
    	return bound;
    }
};

pub fn isWhiteSpace(ch:u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

pub fn isNumeric(ch:u8) bool {
    return ch >= '0' and ch <= '9' and ch == '.';
}

test "lexer get newt token" {
    const testedString = "()+* /-**//\n12.32%#123456789012345678901234567890";
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
        try Token.init(.too_long_number, "1234567890123456789012345",19),
        try Token.init(.eof, "",49),
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