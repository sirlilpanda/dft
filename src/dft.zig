const std = @import("std");
const Random = std.rand.DefaultPrng;
const math = std.math;
const complex = math.complex;
const Allocator = std.mem.Allocator;
var prng = std.rand.DefaultPrng.init(32762);
const rand = prng.random();

const f32c = math.Complex(f32);
const complex_i: f32c = f32c.init(0, 1);

const top: f32c = f32c.init(-2, 0).mul(complex_i).mul(f32c.init(math.pi, 0));

pub fn dft(allocator: Allocator, length: usize, arr: []f32c) ![]f32c {
    var out_arr: []f32c = try allocator.alloc(f32c, length);

    var k: usize = 0;
    while (k < length) : (k += 1) {
        out_arr[k] = dft_summer(arr, length, k);
    }

    return out_arr;
}

fn dft_summer(arr: []f32c, N: usize, k: usize) f32c {
    var sum: f32c = f32c.init(0, 0);
    var n: usize = 0;
    while (n < N) : (n += 1) {
        sum = sum.add(
            arr[n].mul(
                math.complex.exp(
                    top.mul(f32c.init(@as(f32, @floatFromInt(k)), 0))
                        .mul(f32c.init(@as(f32, @floatFromInt(n)), 0))
                        .div(f32c.init(@as(f32, @floatFromInt(N)), 0)),
                ),
            ),
        );
    }
    return sum;
}

pub fn ran_gen_wave_form(allocator: Allocator, length: usize, freqs_amout: usize) ![]f32c {
    var out_arr = try allocator.alloc(f32c, length);

    var freqs_amps = try allocator.alloc(f32c, freqs_amout);
    defer allocator.free(freqs_amps);
    var freqs = try allocator.alloc(f32c, freqs_amout);
    defer allocator.free(freqs);

    var f: usize = 0;

    while (f < freqs_amout) : (f += 1) {
        freqs_amps[f] = f32c.init(
            rand.float(f32) * @as(f32, @floatFromInt(rand.intRangeAtMost(u8, 0, 255))),
            0,
        );
    }

    f = 0;
    while (f < freqs_amout) : (f += 1) {
        freqs[f] = f32c.init(
            rand.float(f32) * @as(f32, @floatFromInt(rand.intRangeAtMost(u8, 0, 255))),
            0,
        );
    }

    var i: usize = 0;
    var j: u32 = 0;
    while (i < length) : (i += 1) out_arr[i] = f32c.init(0, 0);
    i = 0;

    while (i < length) : (i += 1) {
        while (j < freqs_amout) : (j += 1) {
            out_arr[i] = out_arr[i].add(
                freqs_amps[j].mul(
                    math.complex.cos(
                        f32c.init(@as(f32, @floatFromInt(i)), 0).mul(freqs[j]),
                    ),
                ),
            );
        }
        j = 0;
    }
    return out_arr;
}

pub fn set_wave_from_gen(
    allocator: Allocator,
    length: usize,
    sin_freq_amount: usize,
    sin_in_freqs: []f32,
    cos_freq_amount: usize,
    cos_in_freqs: []f32,
) []f32c {
    var out_arr: []f32c = allocator.alloc(f32c, length);
    var sin_freqs: []f32c = allocator.alloc(f32c, sin_freq_amount);
    var cos_freqs: []f32c = allocator.alloc(f32c, cos_freq_amount);
    defer allocator.free(sin_freqs);
    defer allocator.free(cos_freqs);

    var f: u32 = 0;

    while (f < sin_freq_amount) : (f += 1) {
        sin_freqs[f] = f32c.init(
            sin_in_freqs[f],
            0,
        );
    }
    f = 0;
    while (f < cos_freq_amount) : (f += 1) {
        cos_freqs[f] = f32c.init(
            cos_in_freqs[f],
            0,
        );
    }

    var i: usize = 0;
    var j: u32 = 0;

    while (i < length) : (i += 1) out_arr[i] = f32c.init(0, 0);
    i = 0;

    while (i < length) : (i += 1) {
        while (j < sin_freq_amount) : (j += 1) {
            out_arr[i] = out_arr[i].add(
                math.complex.sin(
                    f32c.init(@as(f32, @floatFromInt(i)), 0).mul(sin_freqs[j]),
                ),
            );
        }
        j = 0;
        while (j < cos_freq_amount) : (j += 1) {
            out_arr[i] = out_arr[i].add(
                math.complex.cos(
                    f32c.init(@as(f32, @floatFromInt(i)), 0).mul(cos_freqs[j]),
                ),
            );
        }
        j = 0;
    }
    return out_arr;
}

test "sin(t) + cos(4t)" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const period: f32 = 25;
    _ = period;
    const len: usize = 600;

    const sin_freqs: [1]f32 = [1]f32{
        2 * math.pi / len,
    };
    const cos_freqs: [1]f32 = [1]f32{
        8 * math.pi / len,
    };
    const out = set_wave_from_gen(
        allocator,
        len,
        sin_freqs.len,
        sin_freqs,
        cos_freqs.len,
        cos_freqs,
    );
    defer allocator.free(out);
}
