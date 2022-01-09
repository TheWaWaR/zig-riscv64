const consts = @import("ckb_constants.zig");
const SysError = @import("error.zig").SysError;
const std = @import("std");

const assert = std.debug.assert;
const mem = std.mem;
const Source = consts.Source;
const CellField = consts.CellField;
const HeaderField = consts.HeaderField;
const InputField = consts.InputField;

const BUF_SIZE: usize = 1024;

extern fn syscall(a0: u64, a1: u64, a2: u64, a3: u64, a4: u64, a5: u64, _: u64, a7: u64) u64;

/// Output debug message
pub fn debug(msg: []const u8) void {
    _ = syscall(@ptrToInt(msg.ptr), 0, 0, 0, 0, 0, 0, consts.SYS_DEBUG);
}

/// Exit, this script will be terminated after the exit syscall.
/// exit code `0` represents verification is success, others represent error code.
pub fn exit(code: i8) noreturn {
    _ = syscall(@intCast(u64, @bitCast(u8, code)), 0, 0, 0, 0, 0, 0, consts.SYS_EXIT);
    while (true) {}
}

// Return the actual data length: `actual_len = data.len - min(data.len, offset)`.
fn sysLoad(
    buf: [*]u8,
    len: usize,
    offset: usize,
    a3: u64,
    a4: u64,
    a5: u64,
    syscall_number: u64,
) SysError!usize {
    const ret = syscall(
        @ptrToInt(buf),
        @ptrToInt(&len),
        @intCast(u64, offset),
        a3,
        a4,
        a5,
        0,
        syscall_number,
    );
    return switch (ret) {
        0 => len,
        1 => error.IndexOutOfBound,
        2 => error.ItemMissing,
        3 => error.SliceOutOfBound,
        4 => error.WrongFormat,
        else => unreachable,
    };
}

/// Load transaction hash
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
pub fn loadTxHashRaw(buf: []u8, offset: usize) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        0,
        0,
        0,
        consts.SYS_LOAD_TX_HASH,
    );
}
pub fn loadTxHash() SysError![32]u8 {
    var hash_buf: [32]u8 = undefined;
    const size = try loadTxHashRaw(&hash_buf, 0);
    assert(size == 32);
    return hash_buf;
}

/// Load script hash
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
pub fn loadScriptHashRaw(buf: []u8, offset: usize) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        0,
        0,
        0,
        consts.SYS_LOAD_SCRIPT_HASH,
    );
}
pub fn loadScriptHash() SysError![32]u8 {
    var hash_buf: [32]u8 = undefined;
    const size = try loadScriptHashRaw(&hash_buf, 0);
    assert(size == 32);
    return hash_buf;
}

/// Load cell
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
/// * `index` - index of cell
/// * `source` - source of cell
pub fn loadCell(buf: []u8, offset: usize, index: usize, source: Source) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        @intCast(u64, index),
        @enumToInt(source),
        0,
        consts.SYS_LOAD_CELL,
    );
}

/// Load input
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
/// * `index` - index of cell
/// * `source` - source of cell
pub fn loadInput(buf: []u8, offset: usize, index: usize, source: Source) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        @intCast(u64, index),
        @enumToInt(source),
        0,
        consts.SYS_LOAD_INPUT,
    );
}

/// Load header
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
/// * `index` - index of cell or header
/// * `source` - source
pub fn loadHeader(buf: []u8, offset: usize, index: usize, source: Source) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        @intCast(u64, index),
        @enumToInt(source),
        0,
        consts.SYS_LOAD_HEADER,
    );
}

/// Load witness
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
/// * `index` - index of cell
/// * `source` - source
pub fn loadWitness(buf: []u8, offset: usize, index: usize, source: Source) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        @intCast(u64, index),
        @enumToInt(source),
        0,
        consts.SYS_LOAD_WITNESS,
    );
}

/// Load transaction
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
pub fn loadTransaction(buf: []u8, offset: usize) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        0,
        0,
        0,
        consts.SYS_LOAD_TRANSACTION,
    );
}

/// Load cell by field
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
/// * `index` - index of cell
/// * `source` - source of cell
/// * `field` - field of cell
pub fn loadCellByField(
    buf: []u8,
    offset: usize,
    index: usize,
    source: Source,
    field: CellField,
) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        @intCast(u64, index),
        @enumToInt(source),
        @enumToInt(field),
        consts.SYS_LOAD_CELL_BY_FIELD,
    );
}

/// Load header by field
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
/// * `index` - index
/// * `source` - source
/// * `field` - field
pub fn loadHeaderByField(
    buf: []u8,
    offset: usize,
    index: usize,
    source: Source,
    field: HeaderField,
) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        @intCast(u64, index),
        @enumToInt(source),
        @enumToInt(field),
        consts.SYS_LOAD_HEADER_BY_FIELD,
    );
}

/// Load input by field
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
/// * `index` - index
/// * `source` - source
/// * `field` - field
pub fn loadInputByField(
    buf: []u8,
    offset: usize,
    index: usize,
    source: Source,
    field: InputField,
) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        @intCast(u64, index),
        @enumToInt(source),
        @enumToInt(field),
        consts.SYS_LOAD_INPUT_BY_FIELD,
    );
}

/// Load cell data, read cell data
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
/// * `index` - index
/// * `source` - source
pub fn loadCellData(
    buf: []u8,
    offset: usize,
    index: usize,
    source: Source,
) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        @intCast(u64, index),
        @enumToInt(source),
        0,
        consts.SYS_LOAD_CELL_DATA,
    );
}

/// Load script
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf` - a writable buf used to receive the data
/// * `offset` - offset
pub fn loadScriptRaw(buf: []u8, offset: usize) SysError!usize {
    return sysLoad(
        buf.ptr,
        buf.len,
        offset,
        0,
        0,
        0,
        consts.SYS_LOAD_SCRIPT,
    );
}
pub fn loadScript(allocator: mem.Allocator) anyerror![]u8 {
    var script_buf: [BUF_SIZE]u8 = undefined;
    const size = try loadScriptRaw(script_buf[0..BUF_SIZE], 0);
    var result_buf: []u8 = try allocator.alloc(u8, size);
    mem.copy(u8, result_buf, script_buf[0..@minimum(BUF_SIZE, size)]);
    if (size > BUF_SIZE) {
        const new_size = try loadScriptRaw(result_buf[BUF_SIZE..size], BUF_SIZE);
        assert(new_size + BUF_SIZE == size);
    }
    return result_buf;
}

/// Load cell code, read cell data as executable code
///
/// Return the actual data length or a syscall error
///
/// # Arguments
///
/// * `buf_ptr` - a writable pointer used to receive the data
/// * `len` - length that the `buf_ptr` can receives.
/// * `content_offset` - offset
/// * `content_size` - read length
/// * `index` - index
/// * `source` - source
pub fn loadCellCode(
    buf: [*]u8,
    len: usize,
    content_offset: usize,
    content_size: usize,
    index: usize,
    source: Source,
) SysError!usize {
    return sysLoad(
        buf,
        len,
        @intCast(u64, content_offset),
        @intCast(u64, content_size),
        @intCast(u64, index),
        @enumToInt(source),
        consts.SYS_LOAD_CELL_DATA_AS_CODE,
    );
}

/// *VM version* syscall returns current running VM version, so far 2 values will be returned:
///   - Error for Lina CKB-VM version
///   - 1 for the new hardfork CKB-VM version.
///
/// This syscall consumes 500 cycles.
pub fn vmVersion() u64 {
    return syscall(0, 0, 0, 0, 0, 0, 0, consts.SYS_VM_VERSION);
}

/// *Current Cycles* returns current cycle consumption just before executing this syscall.
///  This syscall consumes 500 cycles.
pub fn currentCycles() u64 {
    return syscall(0, 0, 0, 0, 0, 0, 0, consts.SYS_CURRENT_CYCLES);
}

/// Exec runs an executable file from specified cell data in the context of an
/// already existing machine, replacing the previous executable. The used cycles
/// does not change, but the code, registers and memory of the vm are replaced
/// by those of the new program. It's cycles consumption consists of two parts:
///
/// - Fixed 500 cycles
/// - Initial Loading Cycles (https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0014-vm-cycle-limits/0014-vm-cycle-limits.md)
///
/// The arguments used here are:
///
///   * `index`: an index value denoting the index of entries to read.
///   * `source`: a flag denoting the source of cells or witnesses to locate, possible values include:
///       + 1: input cells.
///       + `0x0100000000000001`: input cells with the same running script as current script
///       + 2: output cells.
///       + `0x0100000000000002`: output cells with the same running script as current script
///       + 3: dep cells.
///   * `place`: A value of 0 or 1:
///       + 0: read from cell data
///       + 1: read from witness
///   * `bounds`: high 32 bits means `offset`, low 32 bits means `length`. if `length` equals to zero, it read to end instead of reading 0 bytes.
///   * `argc`: argc contains the number of arguments passed to the program
///   * `argv`: argv is a one-dimensional array of strings
pub fn exec(
    index: usize,
    source: Source,
    place: usize,
    bounds: usize,
    argv: [][*:0]u8,
) u64 {
    const argc: u64 = argv.len;
    return syscall(
        @intCast(u64, index),
        @enumToInt(source),
        @intCast(u64, place),
        @intCast(u64, bounds),
        argc,
        @ptrToInt(argv.ptr),
        0,
        consts.SYS_EXEC,
    );
}

test "check all syscalls decls" {
    std.testing.refAllDecls(@This());
}
