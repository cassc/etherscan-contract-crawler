// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Batch Transfer.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0xf3993d11.
interface IERC721BatchTransfer {
    /// @notice Unsafely transfers a batch of tokens to a recipient.
    /// @dev Resets the token approval for each of `tokenIds`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits an {IERC721-Transfer} event for each of `tokenIds`.
    /// @param from Current tokens owner.
    /// @param to Address of the new token owner.
    /// @param tokenIds Identifiers of the tokens to transfer.
    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external;
}