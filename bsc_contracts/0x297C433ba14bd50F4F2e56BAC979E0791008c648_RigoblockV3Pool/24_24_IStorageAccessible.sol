// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.7.0 <0.9.0;

/// @title IStorageAccessible - generic base interface that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
interface IStorageAccessible {
    /// @notice Reads `length` bytes of storage in the currents contract.
    /// @param offset - the offset in the current contract's storage in words to start reading from.
    /// @param length - the number of words (32 bytes) of data to read.
    /// @return Bytes string of the bytes that were read.
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

    /// @notice Reads bytes of storage at different storage locations.
    /// @dev Returns a string with values regarless of where they are stored, i.e. variable, mapping or struct.
    /// @param slots The array of storage slots to query into.
    /// @return Bytes string composite of different storage locations' value.
    function getStorageSlotsAt(uint256[] memory slots) external view returns (bytes memory);
}