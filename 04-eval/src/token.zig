pub const maxLiteralLen = 25;

pub const TokenType = enum{
	left_par,right_par,
	plus,star,slash,minus,
	double_star,double_slash,percent,
	number,
	illegal,too_long_number,
	eof,
};

pub const Token = struct{
    type: TokenType,
    literal: [maxLiteralLen:0]u8,
    pos: usize,
    len: usize,

    pub fn init(typ: TokenType, lit: []const u8, pos: usize) Token {
        var literal: [maxLiteralLen:0]u8 = undefined;
        const len = @min(lit.len, maxLiteralLen);
        @memcpy( literal[0..len], lit);
        if (len < maxLiteralLen) {
            @memset(literal[len..], 0);
        }
        return Token{
            .type = typ,
            .literal = literal,
            .pos = pos,
            .len = len,
        };
    }
};