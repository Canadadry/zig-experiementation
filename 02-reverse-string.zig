const std = @import("std");

pub fn reverse(allocator: std.mem.Allocator,str: []const u8) anyerror![]const u8{
	var out = try allocator.alloc(u8,str.len);
	var i:usize=0;
	while(i<str.len){
		out[i]=str[str.len-1-i];
		i=i+1;
	}
	return out;
}

pub fn unicode_reverse(allocator: std.mem.Allocator,str: []const u8) anyerror![]const u8{
	var out = try allocator.alloc(u8,str.len);
	var pos:usize=str.len-1;
	var code_point_iterator = (try std.unicode.Utf8View.init(str)).iterator();
	while (code_point_iterator.nextCodepoint()) |cp| {
		var buf: [4]u8 = [_]u8{undefined} ** 4;
		const len = try std.unicode.utf8Encode(cp, &buf);
		for(0..len)|i|{
			const at = pos+1-len;
			//std.debug.print("write byte '{u}' at {d} with str len of {d} and rune len of {d} \n", .{cp,at,str.len,len});
			out[at+i]=buf[i];
		}
		if(pos>=len){
			pos=pos-len;
		}
	}
	return out;
}

pub fn main() !void {
	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	const allocator = gpa.allocator();
	const txt = "bonjour école";

	const rev = try reverse(allocator,txt);
	defer allocator.free(rev);
	std.debug.print("'{s}' reversed to \n'{s}'\n",.{txt,rev});

	const unicode_rev = try unicode_reverse(allocator,txt);
	defer allocator.free(unicode_rev);
	std.debug.print("'{s}' unicode reversed to \n'{s}'\n",.{txt,unicode_rev});
}
