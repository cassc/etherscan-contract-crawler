// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Deliverable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x9da5e832.
interface IERC721Deliverable {
    /// @notice Unsafely mints tokens to multiple recipients.
    /// @dev Reverts if `recipients` and `tokenIds` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address for each of `recipients` and `tokenIds`.
    /// @param recipients Addresses of the new tokens owners.
    /// @param tokenIds Identifiers of the tokens to mint.
    function deliver(address[] calldata recipients, uint256[] calldata tokenIds) external;
}