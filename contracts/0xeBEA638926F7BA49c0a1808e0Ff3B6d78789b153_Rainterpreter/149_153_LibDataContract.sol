// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "sol.lib.memory/LibPointer.sol";

/// Thrown if writing the data by creating the contract fails somehow.
error WriteError();

/// Thrown if reading a zero length address.
error ReadError();

/// @dev SSTORE2 Verbatim reference
/// https://github.com/0xsequence/sstore2/blob/master/contracts/utils/Bytecode.sol#L15
///
/// 0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
/// 0x01    0x80         0x80        DUP1                size size
/// 0x02    0x60         0x600e      PUSH1 14            14 size size
/// 0x03    0x60         0x6000      PUSH1 00            0 14 size size
/// 0x04    0x39         0x39        CODECOPY            size
/// 0x05    0x60         0x6000      PUSH1 00            0 size
/// 0x06    0xf3         0xf3        RETURN
/// <CODE>
///
/// However note that 00 is also prepended (although docs say append) so there's
/// an additional byte that isn't described above.
/// https://github.com/0xsequence/sstore2/blob/master/contracts/SSTORE2.sol#L25
///
/// Note also typo 0x63XXXXXX which indicates 3 bytes but instead 4 are used as
/// 0x64XXXXXXXX.
///
/// Note also that we don't need 4 bytes to represent the size of a contract as
/// 24kb is the max PUSH2 (0x61) can be used instead of PUSH4 for code length.
/// This also changes the 0x600e to 0x600c as we've reduced prefix size by 2
/// relative to reference implementation.
/// https://github.com/0xsequence/sstore2/pull/5/files
uint256 constant BASE_PREFIX = 0x61_0000_80_600C_6000_39_6000_F3_00_00000000000000000000000000000000000000;

/// @dev Length of the prefix that converts in memory data to a deployable
/// contract.
uint256 constant PREFIX_BYTES_LENGTH = 13;

/// A container is a region of memory that is directly deployable with `create`,
/// without length prefixes or other Solidity type trappings. Where the length is
/// needed, such as in `write` it can be read as bytes `[1,2]` from the prefix.
/// This is just a pointer but given a new type to help avoid mistakes.
type DataContractMemoryContainer is uint256;

/// @title DataContract
///
/// DataContract is a simplified reimplementation of
/// https://github.com/0xsequence/sstore2
///
/// - Doesn't force additonal internal allocations with ABI encoding calls
/// - Optimised for the case where the data to read/write and contract are 1:1
/// - Assembly optimisations for less gas usage
/// - Not shipped with other unrelated code to reduce dependency bloat
/// - Fuzzed with foundry
///
/// It is a little more low level in that it doesn't work on `bytes` from
/// Solidity but instead requires the caller to copy memory directy by pointer.
/// https://github.com/rainprotocol/sol.lib.bytes can help with that.
library LibDataContract {
    /// Prepares a container ready to write exactly `length_` bytes at the
    /// returned `pointer_`. The caller MUST write exactly the number of bytes
    /// that it asks for at the pointer otherwise memory WILL be corrupted.
    /// @param length_ Caller specifies the number of bytes to allocate for the
    /// data it wants to write. The actual size of the container in memory will
    /// be larger than this due to the contract creation prefix and the padding
    /// potentially required to align the memory allocation.
    /// @return container_ The pointer to the start of the container that can be
    /// deployed as an onchain contract. Caller can pass this back to `write` to
    /// have the data contract deployed
    /// (after it copies its data to the pointer).
    /// @return pointer_ The caller can copy its data at the pointer without any
    /// additional allocations or Solidity type wrangling.
    function newContainer(uint256 length_)
        internal
        pure
        returns (DataContractMemoryContainer container_, Pointer pointer_)
    {
        unchecked {
            uint256 prefixBytesLength_ = PREFIX_BYTES_LENGTH;
            uint256 basePrefix_ = BASE_PREFIX;
            assembly ("memory-safe") {
                // allocate output byte array - this could also be done without assembly
                // by using container_ = new bytes(size)
                container_ := mload(0x40)
                // new "memory end" including padding
                mstore(0x40, add(container_, and(add(add(length_, prefixBytesLength_), 0x1f), not(0x1f))))
                // pointer is where the caller will write data to
                pointer_ := add(container_, prefixBytesLength_)

                // copy length into the 2 bytes gap in the base prefix
                let prefix_ :=
                    or(
                        basePrefix_,
                        shl(
                            // length sits 29 bytes from the right
                            232,
                            and(
                                // mask the length to 2 bytes
                                0xFFFF,
                                add(length_, 1)
                            )
                        )
                    )
                mstore(container_, prefix_)
            }
        }
    }

    /// Given a container prepared by `newContainer` and populated with bytes by
    /// the caller, deploy to a new onchain contract and return the contract
    /// address.
    /// @param container_ The container full of data to deploy as an onchain data
    /// contract.
    /// @return The newly deployed contract containing the data in the container.
    function write(DataContractMemoryContainer container_) internal returns (address) {
        address pointer_;
        uint256 prefixLength_ = PREFIX_BYTES_LENGTH;
        assembly ("memory-safe") {
            pointer_ :=
                create(
                    0,
                    container_,
                    add(
                        prefixLength_,
                        // Read length out of prefix.
                        and(0xFFFF, shr(232, mload(container_)))
                    )
                )
        }
        // Zero address means create failed.
        if (pointer_ == address(0)) revert WriteError();
        return pointer_;
    }

    /// Reads data back from a previously deployed container.
    /// Almost verbatim Solidity docs.
    /// https://docs.soliditylang.org/en/v0.8.17/assembly.html#example
    /// Notable difference is that we skip the first byte when we read as it is
    /// a `0x00` prefix injected by containers on deploy.
    /// @param pointer_ The address of the data contract to read from. MUST have
    /// a leading byte that can be safely ignored.
    /// @return data_ The data read from the data contract. First byte is skipped
    /// and contract is read completely to the end.
    function read(address pointer_) internal view returns (bytes memory data_) {
        uint256 size_;
        assembly ("memory-safe") {
            // Retrieve the size of the code, this needs assembly.
            size_ := extcodesize(pointer_)
        }
        if (size_ == 0) revert ReadError();
        assembly ("memory-safe") {
            // Skip the first byte.
            size_ := sub(size_, 1)
            // Allocate output byte array - this could also be done without
            // assembly by using data_ = new bytes(size)
            data_ := mload(0x40)
            // New "memory end" including padding.
            // Compiler will optimise away the double constant addition.
            mstore(0x40, add(data_, and(add(add(size_, 0x20), 0x1f), not(0x1f))))
            // Store length in memory.
            mstore(data_, size_)
            // actually retrieve the code, this needs assembly
            // skip the first byte
            extcodecopy(pointer_, add(data_, 0x20), 1, size_)
        }
    }

    /// Hybrid of address-only read, SSTORE2 read and Solidity docs.
    /// Unlike SSTORE2, reading past the end of the data contract WILL REVERT.
    /// @param pointer_ As per `read`.
    /// @param start_ Starting offset for reads from the data contract.
    /// @param length_ Number of bytes to read.
    function readSlice(address pointer_, uint16 start_, uint16 length_) internal view returns (bytes memory data_) {
        uint256 size_;
        // uint256 offset and end avoids overflow issues from uint16.
        uint256 offset_;
        uint256 end_;
        assembly ("memory-safe") {
            // Skip the first byte.
            offset_ := add(start_, 1)
            end_ := add(offset_, length_)
            // Retrieve the size of the code, this needs assembly.
            size_ := extcodesize(pointer_)
        }
        if (size_ < end_) revert ReadError();
        assembly ("memory-safe") {
            // Allocate output byte array - this could also be done without
            // assembly by using data_ = new bytes(size)
            data_ := mload(0x40)
            // New "memory end" including padding.
            // Compiler will optimise away the double constant addition.
            mstore(0x40, add(data_, and(add(add(length_, 0x20), 0x1f), not(0x1f))))
            // Store length in memory.
            mstore(data_, length_)
            // actually retrieve the code, this needs assembly
            extcodecopy(pointer_, add(data_, 0x20), offset_, length_)
        }
    }
}