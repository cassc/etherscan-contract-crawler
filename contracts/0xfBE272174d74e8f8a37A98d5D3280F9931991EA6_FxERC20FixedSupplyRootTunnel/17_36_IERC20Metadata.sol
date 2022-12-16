// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, ERC1046 optional extension: Metadata.
/// @dev See https://eips.ethereum.org/EIPS/eip-1046
/// @dev Note: the ERC-165 identifier for this interface is 0x3c130d90.
interface IERC20Metadata {
    /// @notice Gets the token metadata URI.
    /// @return uri The token metadata URI.
    function tokenURI() external view returns (string memory uri);
}