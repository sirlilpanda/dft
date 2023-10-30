const std = @import("std");
const fft = @import("fft.zig");
const time = std.time;

const Random = std.rand.DefaultPrng;
// const dft(f32c)
const Allocator = std.mem.Allocator;

const math = std.math;
const complex = math.complex;
const dft = @import("dft.zig");

var prng = std.rand.DefaultPrng.init(32762);
const rand = prng.random();

const f32c = math.Complex(f32);

fn term_print(comptime length: usize, arr: [length]f32c) void {
    for (arr) |a| {
        var i: u64 = 0;

        var amount: i16 = @as(i16, @intFromFloat(a.re)) + 127;
        while (i < amount) : (i += 1) {
            std.debug.print(" ", .{});
        }

        std.debug.print("[]\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // decoding command line args
    const num_samples: usize = try std.fmt.parseInt(usize, args[1], 10);
    const num_freqs: usize = try std.fmt.parseInt(usize, args[2], 10);

    const len: usize = num_samples;

    const out = try dft.ran_gen_wave_form(allocator, len, num_freqs);
    defer allocator.free(out);

    var freqs: fft.real_im_arr = try fft.complex_arr_to_real_im(f32c, allocator, len, out);
    defer allocator.free(freqs.im);
    defer allocator.free(freqs.real);

    var timer = try time.Timer.start();

    const fre = try dft.dft(allocator, len, out);
    defer allocator.free(fre);

    std.debug.print("dft : {}, ", .{timer.lap()});

    _ = timer.lap(); // makes sure that the print doesnt effect the timer
    _ = try fft.fft(f32, freqs.real, freqs.im);

    std.debug.print("fft : {}, length : {}\n", .{ timer.lap(), len });
}
