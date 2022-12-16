// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Standard Signature Validation Method for Contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-1271
interface IERC1271 {
    /// @notice Returns whether the signature is valid for the data hash.
    /// @param hash The hash of the signed data.
    /// @param signature The signature for `hash`.
    /// @return magicValue `0x1626ba7e` (`bytes4(keccak256("isValidSignature(bytes32,bytes)")`) if the signature is valid, else any other value.
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}