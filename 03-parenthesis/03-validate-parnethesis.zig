const std = @import("std");

pub fn is_parenthesis_valid(str: []const u8) bool {
    var count: i32 = 0;
    for (0..str.len) |i| {
        if (str[i] == '(') {
            count = count + 1;
        } else {
            count = count - 1;
            if (count < 0) {
                return false;
            }
        }
    }
    return count == 0;
}

test "is_parenthesis" {
	const tests = [_]struct {
		case: []const u8,
		exp: bool,
	}{
		.{.case="()",.exp=true,},
		.{.case="()()",.exp=true,},
		.{.case="(()",.exp=false,},
		.{.case="())()",.exp=false,},
		.{.case="()(()",.exp=false,},
	};

    for (tests) |tt| {
        const result = is_parenthesis_valid(tt.case);
        std.testing.expectEqual(tt.exp, result) catch |err| {
            std.debug.print("FAIL [{s}]: expected {}, got {}\n", .{ tt.case, tt.exp, result });
            return err;
        };
    }
}
