// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @title IExtrospectBytecodeV2
/// @notice External functions for offchain processing to conveniently access the
/// view on contract code that is exposed to EVM opcodes. Generally this is NOT
/// useful onchain as all contracts have access to the same opcodes, so would be
/// more gas efficient and convenient calling the opcodes internally than an
/// external call to an extrospection contract.
interface IExtrospectBytecodeV2 {
    /// Return the bytecode for an address.
    ///
    /// Equivalent to `account.code`.
    ///
    /// @param account The account to get bytecode for.
    /// @return The bytecode of `account`. Will be `0` length for non-contract
    /// accounts.
    function bytecode(address account) external view returns (bytes memory);

    /// Return the hash of the complete bytecode for an address.
    ///
    /// Equivalent to `account.codehash`.
    ///
    /// @param account The account to get the bytecode hash for.
    /// @return The hash of the bytecode of `account`. Will be `0` (NOT the hash
    /// of empty bytes) for non-contract accounts.
    function bytecodeHash(address account) external view returns (bytes32);

    /// Scan every byte of the bytecode in some account and return an encoded
    /// list of every opcode present in that account's code. The list is encoded
    /// as a single `uint256` where each bit is a flag representing the presence
    /// of an opcode in the source bytecode. The opcode byte is the literal
    /// bitwise offset in the final output, starting from least significant bits.
    ///
    /// E.g. opcode `0` sets the 0th bit, i.e. `2 ** 0`, i.e. `1`, i.e. `1 << 0`.
    /// opcode `0x50` sets the `0x50`th bit, i.e. `2 ** 0x50`, i.e. `1 << 0x50`.
    ///
    /// The final output can be bitwise `&` against a reference set of bit flags
    /// to check for the presence of a list of (un)desired opcodes in a single
    /// logical operation. This allows for fewer branching operations (expensive)
    /// per byte, but precludes the ability to break the loop early upon
    /// discovering the prescence of a specific opcode.
    ///
    /// The scan MUST respect the inline skip behaviour of the `PUSH*` family of
    /// evm opcodes, starting from opcode `0x60` through `0x7F` inclusive. These
    /// opcodes are followed by literal bytes that will be pushed to the EVM
    /// stack at runtime and so are NOT opcodes themselves. Even though each byte
    /// of the data following a `PUSH*` is assigned program counter, it DOES NOT
    /// run as an opcode. Therefore, the scanner MUST ignore all push data,
    /// otherwise it will report false positives from stack data being treated as
    /// opcodes. The relative index of each `PUSH` opcode signifies how many
    /// bytes to skip, e.g. `0x60` skips 1 byte, `0x61` skips 2 bytes, etc.
    /// @param account The account to scan for opcodes.
    /// @return scan A single `uint256` where each bit represents the presence of
    /// an opcode in the source bytecode.
    function scanEVMOpcodesPresentInAccount(address account) external view returns (uint256 scan);

    /// Identical to `scanEVMOpcodesPresentInAccount` except that it skips the
    /// regions of the bytecode that are unreachable by the EVM. This is
    /// generally achieved by pausing the scan any time a halting opcode is
    /// encountered then resuming the scan at the next jump destination. This
    /// scan results in fewer false positives but is less conservative as it
    /// relies on details of the EVM execution model that may change in the
    /// future, and is a more complex algorithm so more susceptible to potential
    /// implementation bugs.
    /// @param account The account to scan for opcodes.
    /// @return scan A single `uint256` where each bit represents the presence of
    /// a reachable opcode in the source bytecode.
    function scanEVMOpcodesReachableInAccount(address account) external view returns (uint256 scan);
}