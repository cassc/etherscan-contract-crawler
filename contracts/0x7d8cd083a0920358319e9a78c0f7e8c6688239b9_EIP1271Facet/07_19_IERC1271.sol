//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev ERC1271 support. You can read more here:
/// https://eips.ethereum.org/EIPS/eip-1271
interface IERC1271 {
    /// @return magicValue the magicValue if the provided signature is valid
    /// @param hash of the data to be signed
    /// @param signature of hash
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
}