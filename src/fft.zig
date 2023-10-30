//=============================================================
// THIS CODE IS FORM
//
// https://github.com/shimamura-sakura/zig-fft/blob/main/fft.zig
//
// EXECPT for complex_arr_to_real_im
//
//=============================================================

const std = @import("std");
const PI = std.math.pi;

const Allocator = std.mem.Allocator;
pub const FFTError = error{ SizeNotEql, SizeNotPow2 };

pub const real_im_arr = struct {
    im: []f32,
    real: []f32,
};

pub fn complex_arr_to_real_im(comptime complex_type: type, allocator: Allocator, length: usize, arr: []complex_type) !real_im_arr {
    const im: []f32 = try allocator.alloc(f32, length);
    const real: []f32 = try allocator.alloc(f32, length);

    for (arr, 0..) |n, i| {
        im[i] = n.im;
        real[i] = n.re;
    }

    return real_im_arr{
        .im = im,
        .real = real,
    };
}

pub fn fft(comptime F: type, real: []F, imag: []F) FFTError!void {
    if (real.len != imag.len) return FFTError.SizeNotEql;
    if (@popCount(real.len) != 1) return FFTError.SizeNotPow2;
    shuffle(F, real, imag);
    compute(F, real, imag);
}

pub fn ifft(comptime F: type, real: []F, imag: []F) FFTError!void {
    if (real.len != imag.len) return FFTError.SizeNotEql;
    if (@popCount(real.len) != 1) return FFTError.SizeNotPow2;
    for (imag) |*v| v.* = -v.*;
    fft(F, real, imag) catch unreachable;
    for (real) |*v| v.* /= @as(F, @floatFromInt(real.len));
    for (imag) |*v| v.* /= @as(F, @floatFromInt(imag.len)) * -1.0;
}

fn shuffle(comptime F: type, real: []F, imag: []F) void {
    const shrAmount = @bitSizeOf(usize) - @ctz(real.len);
    const shrAmtType = std.meta.Int(.unsigned, @ctz(@as(u8, @bitSizeOf(usize))));
    for (real, 0..) |_, i| {
        const j = @bitReverse(i) >> @as(shrAmtType, @intCast(shrAmount));
        if (i >= j) continue;
        std.mem.swap(F, &real[i], &real[j]);
        std.mem.swap(F, &imag[i], &imag[j]);
    }
}

fn compute(comptime F: type, real: []F, imag: []F) void {
    var step: usize = 1;
    while (step < real.len) : (step <<= 1) {
        var group: usize = 0;
        const jump = step << 1;
        while (group < step) : (group += 1) {
            const t_re = @cos(-PI * @as(F, @floatFromInt(group)) / @as(F, @floatFromInt(step)));
            const t_im = @sin(-PI * @as(F, @floatFromInt(group)) / @as(F, @floatFromInt(step)));
            var pair = group;
            while (pair < real.len) : (pair += jump) {
                const match = pair + step;
                const p_re = t_re * real[match] - t_im * imag[match];
                const p_im = t_im * real[match] + t_re * imag[match];
                real[match] = real[pair] - p_re;
                imag[match] = imag[pair] - p_im;
                real[pair] += p_re;
                imag[pair] += p_im;
            }
        }
    }
}
